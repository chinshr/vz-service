class EmailProcessor
  class << self
    def process(email)
      process_audio(email)
    end
  
    protected
  
    def process_audio(email)
      user, message, exception = nil, nil, nil
      if email.attachments.count > 0
        user    = User.find_or_initialize_by(email: Helper::Mailer::unprettify(email.from))
        message = Message::Inbound.new do |m|
          m.to      = address_join(email.to)
          m.cc      = email.cc.map {|e| e[:email]}.join(",")
          m.from    = email.from
          m.subject = email.subject
          m.body    = email.body
          m.text    = email.raw_text
          m.html    = email.raw_html
          m.sender  = user
        end

        email.attachments.each do |attached_file|
          if Upload::Audio.accepted_audio_file_type?(attached_file.content_type)
            upload = with message.attachments.build(:type => "audio") do |upload|
              upload.user        = user
              upload.title       = if email.subject.blank? 
                Upload.humanized_file_name(attached_file.original_filename)
              else
                email.subject
              end
              upload.description = email.body
              upload.file_name   = attached_file.original_filename
              upload.file_size   = attached_file.tempfile.size
              upload.file_type   = attached_file.content_type
              upload.locale      = message.locale
              upload.privacy     = [:private]
            end

            key = Upload.generate_object_name
            upload_file_to_s3_bucket(attached_file.tempfile.path, key)
            upload.s3_url = "#{APP_CONFIG['S3_URL']}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{key}"

            message.save
          end
        end
      else
        Rails.logger.warn "Thanks #{email.from} for your message, but we didn't find any audio attachments."
      end
    rescue Exception => exception
      log_exception(exception)
    ensure
      if message && message.valid? && message.attachments.count > 0
        EndpointMailer.valid_message(message).deliver
        Rails.logger.info "Message and attachments were successfully received."
      else
        Rails.logger.error email.inspect
        log_model_errors(user, message)
        EndpointMailer.invalid_message(message).deliver if message && !message.valid?
        message.sender = nil if user && user.new_record?  # make sure we are not signing up the user if something went wrong!
        message.save(:validate => false) if message  # save message anyway!

        Rails.logger.error "Oops, we've noticed an error when processing this message."
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
  end
end