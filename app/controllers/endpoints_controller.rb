# /endpoints/receive_email.xml
class EndpointsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :clean_fields
  
  def receive_email
    begin
      if (attachments_count = params["attachments"]) && attachments_count > 0
        @user = User.find_or_create_by_email(Helper::Mailer::unprettify(params["from"]))

        @message = Message::Inbound.create!(message_params) do |message|
          message.sender = @user
        end

        attachments_count.times do |index|
          attached_file = params["attachment#{index + 1}"]
        
          upload = with Upload.new(:type => "audio") do |upload|
            upload.user        = @user
            upload.title       = @message.subject
            upload.description = @message.text
            upload.file_name   = attached_file.original_filename
            upload.file_type   = attached_file.content_type
            upload.file_size   = attached_file.tempfile.size
            upload.locale      = @message.locale
            upload.privacy     = [:private]
          end
        
          key = Upload.generate_object_name
          upload_file_to_s3_bucket(attached_file.tempfile.path, key)
          upload.s3_url = "#{APP_CONFIG['S3_URL']}#{APP_CONFIG['S3_INBOUND_BUCKET']}/#{key}"
          upload.save
          
          @message.attachments << upload
        end
      else
        Rails.logger.warn "Thanks #{@user.email} for your message, but we didn't find any audio attachments."
      end
    rescue Exception => ex
      logger(ex)
    ensure
      respond_to do |format|
        if @message && @message.valid? && @message.valid_attachments?
          flash[:notice] = "Message and attachments were successfully received."
          format.xml {render :xml => @message, :status => :created}
        else
          EndpointMailer.invalid_attachment(@upload).deliver if @upload && !@upload.valid?
          
          flash[:notice]= "Oops, we had an error reading this message."
          format.xml {render :xml => @message ? @message.errors : {code: -1, message: "unparseable"}, :status => :unprocessable_entity}
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
  
  def clean_field(input_string)
    input_string.gsub(/\n/, "") if input_string
  end
  
  def message_params
    params.permit(:text, :html, :from, :to, :cc, :subject)
  end
  
  def upload_file_to_s3_bucket(file_path, key = nil)
    s3 = AWS::S3.new
    key = File.basename(file_path)
    s3.buckets[APP_CONFIG['S3_INBOUND_BUCKET']].objects[key].write(:file => file_path)
  end

  def logger(exception)
    errors = ""
    errors += ("=" * 80) + "\n"
    errors += exception.message + "\n"
    errors += " * @user: #{@user.errors.full_messages.join(', ')}\n" if @user && !@user.valid?
    errors += " * @message: #{@message.errors.full_messages.join(', ')}\n" if @message && !@message.valid?
    errors += " * @upload: #{@upload.errors.full_messages.join(', ')}\n" if @upload && !@upload.valid?
    errors += ("-" * 80) + "\n"
    errors += exception.backtrace.join("\n")
    errors += ("=" * 80) + "\n"
    Rails.logger.error errors
  end
  
end
