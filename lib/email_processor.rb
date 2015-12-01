class EmailProcessor
  class << self
    def process(email)
      process_attachments(email)
    end

    protected

    def process_attachments(email)
      user, message, exception = nil, nil, nil
      if email.attachments.count > 0
        user    = User.find_or_initialize_by(email: Mailer::Helper::unprettify(email.from))
        message = Message::Inbound.new do |m|
          m.to      = address_join(email.to)
          m.cc      = address_join(email.cc)
          m.from    = email.from
          m.subject = email.subject
          m.body    = email.body
          m.text    = email.raw_text
          m.html    = email.raw_html
          m.sender  = user
        end

        email.attachments.each do |attached_file|
          content_type = mime_type(attached_file.tempfile.path) || attached_file.content_type
          if upload_class_name = Upload.class_name_from_content_type_for(content_type)
            upload = with message.attachments.build(:type => upload_class_name) do |upload|
              upload.user        = user
              upload.title       = if email.subject.blank?
                Upload.humanized_file_name(attached_file.original_filename)
              else
                email.subject
              end
              upload.description = email.body
              upload.file_name   = attached_file.original_filename
              upload.file_size   = attached_file.tempfile.size
              upload.file_type   = content_type
              upload.locale      = locale_from_email_address(email.to) || message.locale || "en-US"
              upload.privacy     = [:unlisted]
            end

            Rails.logger.info "* mime_type: #{mime_type(attached_file.tempfile.path)}"

            key = Upload.generate_object_name
            upload_file_to_s3_bucket(attached_file.tempfile.path, key)
            upload.s3_url = "#{APP_CONFIG['S3_URL']}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{key}"

            message.save

            Rails.logger.error "* Message invalid: #{message.inspect}" unless message.valid?
            Rails.logger.error "** Message attachment invalid: #{upload.inspect}" unless upload.valid?
          else
            Rails.logger.info "* Attachment '#{attached_file.original_filename} (#{content_type}:#{attached_file.content_type})' is not an audio/video file."
          end
        end
      else
        Rails.logger.warn "Thanks #{email.from} for your message, but we didn't find any audio/video attachments."
      end
    rescue Exception => exception
      log_exception(exception)
      Rails.logger.error "Oops, we've noticed an exception while processing this message."
    ensure
      if message && message.valid? && message.attachments.count > 0
        EmailProcessorMailer.valid_message(message).deliver
        Rails.logger.info "Message and attachments were successfully received."
      else
        # Rails.logger.error email.inspect
        EmailProcessorMailer.invalid_message(message).deliver if message && !message.valid?
        message.sender = nil if message && user && user.new_record?  # make sure we are not signing up the user if something went wrong!
        message.save(:validate => false) if message  # save message anyway!

        Rails.logger.error "Oops, no user was built." if !user
        Rails.logger.error "Oops, the user cannot be saved." if user && user.new_record?
        Rails.logger.error "Oops, no message was built." if !message
        Rails.logger.error "Oops, the message cannot be saved." if message && !message.valid?
        Rails.logger.error "Oops, we've noticed we could not process any audio/video attachments." if message && message.attachments.count == 0
      end
    end

    private

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

    def log_model_errors(*models)
      errors = ""
      models.compact.each do |record|
        unless record.valid?
          errors += " * #{record.class.name}: #{record.errors.full_messages.join(', ')}\n"
          if record.is_a?(Message)
            record.attachments.each_with_index do |attachment, index|
              errors += " ** @attachment#{index + 1}: #{attachment.errors.full_messages.join(', ')}\n" unless attachment.valid?
            end
          end
        end
      end
      Rails.logger.error errors unless errors.blank?
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

    # E.g. my+en-us@voyz.es or my+de@voyz.es
    def locale_from_email_address(field)
      field.each do | a|
        if (tri = a[:email].split("+")).size > 1
          if (bi = tri.last.split("@")).size > 1
            if bi.first.match(/^([a-z]{2}-[A-Z]{2}|[a-z]{2})$/i)
              return I18n.normalize_locale($1)
            end
          end
        end
      end
      nil
    end

  end
end