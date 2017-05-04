class EmailProcessor
  include ::Job::Helper

  attr_accessor :email, :user, :message, :exception

  URL_REGEXP    = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/i
  EXPAND_LOCALE = {"es" => "es-ES", "en" => "en-US", "de" => "de-DE"}

  class << self

    def process(email)
      new(email)
    end

  end

  def initialize(email)
    @email, @user, @message, @exception = email, nil, nil, nil
    process_email
  end

  protected

  def process_email
    if has_processable_content?
      self.user = find_or_initialize_user_from_email_sender
      self.message = build_message

      # process
      process_attachments if has_attachments?
      process_source_urls if has_source_urls?
      # post-process
      if message && message.attachments.length > 0 && message.valid?
        message.save
        Message::EmailProcessorMailer.valid_message(message).deliver_later
        Rails.logger.info "EmailProcessor: Message and attachments were successfully received."
      else
        Message::EmailProcessorMailer.invalid_message(message).deliver_later if message && !message.valid?

        Rails.logger.error "EmailProcessor: Oops, no user was built." if !user
        Rails.logger.error "EmailProcessor: Oops, the user cannot be saved." if user && user.new_record?
        Rails.logger.error "EmailProcessor: Oops, no message was built." if !message
        Rails.logger.error "EmailProcessor: Oops, the message cannot be saved." if message && !message.valid?
        Rails.logger.error "EmailProcessor: Oops, we've noticed we could not process any audio/video attachments." if message && message.attachments.count == 0
      end
    else
      Rails.logger.warn "EmailProcessor: Received email from #{email.from}, but without processable sources."
    end
  end

  def process_source_urls
    source_urls.each do |source_url|
      with message.attachments.build(:type => "Upload::MediaUpload") do |upload|
        upload.user                   = user
        upload.source_url             = source_url
        upload.locale                 = extract_locale
        upload.privacy                = :private
        upload.use_source_annotations = extract_use_source_annotations
      end
    end
  end

  def process_attachments
    email.attachments.each do |attached_file|
      content_type = mime_type(attached_file.tempfile.path) || attached_file.content_type
      if Upload::MediaUpload.accepted_media_file_type?(content_type)
        key    = Upload.generate_object_name
        upload = with message.attachments.build(type: "Upload::MediaUpload") do |upload|
          upload.user        = user
          upload.title       = if email.subject.blank?
            Upload::MediaUpload::humanize_path(attached_file.original_filename)
          else
            email.subject.titleize
          end
          upload.description = email.body
          upload.file_name   = attached_file.original_filename
          upload.file_size   = attached_file.tempfile.size
          upload.file_type   = content_type
          upload.locale      = extract_locale
          upload.privacy     = [:private]
          upload.source_url  = "#{APP_CONFIG['S3_URL']}/#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{key}"
        end

        if upload.valid?
          upload_file_to_s3_bucket(attached_file.tempfile.path, key)
        else
          # remove invalid attachment and log error
          message.attachments.delete(upload)
          Rails.logger.error "EmailProcessor: Message attachment invalid: #{upload.errors}, inspect #{upload.inspect}"
        end
      else
        Rails.logger.info "EmailProcessor: Invalid content_type '#{attached_file.original_filename} (#{content_type}:#{attached_file.content_type})'."
      end
    end
  end

  private

  def find_or_initialize_user_from_email_sender
    User.where(email: Mailer::Helper::unprettify(email.from)).first_or_initialize
  end

  def build_message
    Message::Inbound.new do |m|
      m.to      = address_join(email.to)
      m.cc      = address_join(email.cc)
      m.from    = email.from
      m.subject = email.subject
      m.body    = email.body
      m.text    = email.raw_text
      m.html    = email.raw_html
      m.sender  = user
    end
  end

  def address_join(field)
    result = field.map {|e| e[:email]}
    result.empty? ? nil : result.join(",")
  end

  def mime_type(file_path)
    mt = if Rails.env.production?
      # Heroku
      `file -ib #{file_path}`.gsub(/\n/, "")
    else
      # BSD
      `file -Ib #{file_path}`.gsub(/\n/, "")
    end
    mt.split(";").first
  rescue
    nil
  end

  def upload_file_to_s3_bucket(file_path, key)
    s3_upload_object(file_path, APP_CONFIG['S3_INBOUND_BUCKET'], key)
  end

  def delete_file_from_s3_bucket(key)
    s3_delete_object_if_exists(APP_CONFIG['S3_INBOUND_BUCKET'], key)
  end

  def log_exception(exception)
    errors = "EmailProcessor:\n"
    errors += ("=" * 80) + "\n"
    errors += exception.message + "\n"
    errors += ("-" * 80) + "\n"
    errors += exception.backtrace.join("\n")
    errors += ("=" * 80) + "\n"
    Rails.logger.error errors
  end

  def has_processable_content?
    has_attachments? || has_source_urls?
  end

  def has_attachments?
    email && email.attachments.count > 0
  end

  def has_source_urls?
    !source_urls.empty?
  end

  def source_urls
    @source_urls ||= begin
      urls = []
      urls += email.subject.scan(URL_REGEXP).map {|url| url.first}.compact if email.subject.present?
      urls += email.body.scan(URL_REGEXP).map {|url| url.first}.compact if email.body.present?
      urls = urls.compact.uniq
      urls = urls.map do |url|
        target = Model::URI::Target.new(url)
        url if target.valid? || (target.valid? && target.valid_media_service?)
      end.compact
      urls
    end
  end

  def extract_locale
    extract_locale_from_directive || extract_locale_from_email_address(email.to) || "en-US"
  end

  # E.g.
  #   "{en}" -> "en-US"
  #   "{en-us}" -> "en-US"
  #   "{es}" -> "es-ES"
  def extract_locale_from_directive
    locale, text = nil, "#{email.subject} #{email.body}"
    if match = text.match(/\{(\w{2})[_-](\w{2})\}/)
      locale = I18n.normalize_locale("#{match[1]}-#{match[2]}")
    elsif match = text.match(/\{(\w{2})\}/)
      locale = I18n.normalize_locale("#{match[1]}")
      locale = I18n.locale_language(locale).to_s == locale ? EXPAND_LOCALE[locale] : locale
    end
    locale
  end

  # fields are [{:token=>"my", :host=>"app.example.com", :email=>"my@app.example.com", :full=>"my@app.example.com", :name=>nil}]
  def extract_locale_from_email_address(fields)
    locale = nil
    Array.wrap(fields).compact.each do |field|
      locale = Mailer::Helper.locale_from_email_address(field[:email])
      locale = I18n.normalize_locale(locale)
      locale = I18n.locale_language(locale).to_s == locale ? EXPAND_LOCALE[locale] : locale
    end
    locale
  end

  # E.g.
  #   "{:-o}" -> true
  def extract_use_source_annotations
    result, text = false, "#{email.subject} #{email.body}"
    result = true if text.match(/\{\:\-\o}/i)
    result
  end
end
