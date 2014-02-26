# /endpoints/receive_email.xml
class EndpointsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :clean_fields
  respond_to :json, :xml
  
  def receive_email
    begin
      if (attachments_count = params["attachments"].to_i) && attachments_count > 0
        attachment_info = params["attachment-info"] ? JSON.parse(params["attachment-info"]) : {}
        charsets        = params["charsets"] ? JSON.parse(params["charsets"]) : {}

        @user    = User.find_or_initialize_by(email: Helper::Mailer::unprettify(params["from"]))
        @message = Message::Inbound.new(message_params(charsets)) do |message|
          message.sender = @user
        end

        attachments_count.times do |index|
          attached_file = params["attachment#{index + 1}"]
          attached_file_info =  attachment_info["attachment#{index + 1}"]
          
          upload = with @message.attachments.build(:type => "audio") do |upload|
            upload.user        = @user
            upload.title       = @message.subject
            upload.description = @message.text
            upload.file_name   = attached_file.original_filename
            upload.file_size   = attached_file.tempfile.size
            upload.file_type   = attached_file_info["type"] || attached_file_info.content_type
            upload.locale      = @message.locale
            upload.privacy     = [:private]
          end

          key = Upload.generate_object_name
          upload_file_to_s3_bucket(attached_file.tempfile.path, key)
          upload.s3_url = "#{APP_CONFIG['S3_URL']}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{key}"

          @message.save
        end
      else
        Rails.logger.warn "Thanks #{@user ? @user.email : ''} for your message, but we didn't find any audio attachments."
      end
    rescue Exception => @exception
      log_exception(@exception)
    ensure
      respond_to do |format|
        if @message && @message.valid? && @message.attachments.count > 0
          EndpointMailer.valid_message(@message).deliver
          Rails.logger.info "Message and attachments were successfully received."
          format.xml {render :xml => @message, :status => :created}
        else
          Rails.logger.error params.inspect
          log_model_errors
          EndpointMailer.invalid_message(@message).deliver if @message && !@message.valid?
          @message.sender = nil if @user && @user.new_record?  # make sure we are not signing up the user if something went wrong!
          @message.save(:validate => false) if @message  # save message anyway!

          Rails.logger.error "Oops, we've noticed an error when processing this message."
          format.xml {render :xml => @message ? @message.errors : {code: -1, message: "unparseable"}, 
            :status => @exception ? :unprocessable_entity : 202}
        end
      end
    end
  end
  
  protected
  
  def clean_fields
    params["from"]    = clean_field(params["from"])
    params["to"]      = clean_field(params["to"])
    params["cc"]      = clean_field(params["cc"])
    params["subject"] = clean_field(params["subject"])
  end
  
  def utf8_encode_params(params, encoding)
    params.inject(ActionController::Parameters.new) do |result, pair|
      result[pair.first] = pair.last.force_encoding('utf-8') if pair.last && pair.last.respond_to?(:force_encoding)
      result
    end
  end
  
  def clean_field(input_string)
    input_string.gsub(/\n/, "") if input_string
  end
  
  def message_params(charsets = nil)
    converted_params = {}
    if charsets.is_a?(Hash)
      charsets.each do |key, source_charset|
        if params[key].is_a?(String)
          converted_params[key] = params[key].force_encoding(source_charset).encode("UTF-8")
        end
      end
    else
      [:text, :html, :from, :to, :cc, :subject].each do |key|
        if params[key].is_a?(String)
          converted_params[key] = params[key].encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
        end
      end
    end
    params.merge(converted_params).permit(:text, :html, :from, :to, :cc, :subject)
  end
  
  def upload_file_to_s3_bucket(file_path, key = nil)
    s3 = AWS::S3.new
    key = key || File.basename(file_path)
    s3.buckets[APP_CONFIG['S3_INBOUND_BUCKET']].objects[key].write(:file => file_path)
  end

  def log_exception(exception)
    errors = ""
    errors += ("=" * 80) + "\n"
    errors += exception.message + "\n"
    errors += ("-" * 80) + "\n"
    errors += exception.backtrace.join("\n")
    errors += ("=" * 80) + "\n"
    Rails.logger.error errors
  end

  def log_model_errors
    errors = ""
    errors += " * @user: #{@user.errors.full_messages.join(', ')}\n" if @user && !@user.valid?
    errors += " * @message: #{@message.errors.full_messages.join(', ')}\n" if @message && !@message.valid?
    @message.attachments.each_with_index do |attachment, index|
      errors += " * @attachment#{index + 1}: #{attachment.errors.full_messages.join(', ')}\n" if !attachment.valid?
    end if @message && !@message.valid?
    Rails.logger.error errors unless errors.blank?
  end
  
end
