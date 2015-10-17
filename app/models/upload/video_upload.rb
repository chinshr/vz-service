class Upload::VideoUpload < ::Upload
  validate :video_file_type

  class << self
    def accepted_file_type?(file_type)
      !!(file_type && file_type.match(/^(video)\/?.*$/))
    end
  end

  protected

  def video_file_type
    errors.add(:file_type, :video_expected) unless self.class.accepted_file_type?(file_type)
  end

  def build_ingest_and_document
    build_ingest(type: "Ingest::VideoIngest", upload: self,
      document: ::Document.new(title: humanized_file_name, locale: "en-US", privacy: :public)) unless ingest
  end
end
