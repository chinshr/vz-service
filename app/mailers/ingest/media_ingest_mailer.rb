class Ingest::MediaIngestMailer < ActionMailer::Base
  default from: "no-reply@voyz.es"

  def finished_processing(ingest)
    @ingest = ingest
    mail(to: @ingest.user.email,
      subject: "Finished, '#{@ingest.title}' has been processed.",
      bcc: APP_CONFIG['ADMIN_EMAIL_ADDRESSES'])
  end
end
