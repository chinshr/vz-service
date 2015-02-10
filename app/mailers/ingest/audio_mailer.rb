class Ingest::AudioMailer < ActionMailer::Base
  default from: "no-reply@voyz.es"

  def finished_processing(ingest)
    @ingest = ingest
    mail(to: @ingest.user.email, subject: "Finished, '#{@ingest.upload.file_name}' has been transcribed.")
  end

end