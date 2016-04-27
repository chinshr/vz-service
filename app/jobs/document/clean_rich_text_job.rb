class Document::CleanRichTextJob < ActiveJob::Base
  queue_as :default

  def perform(document_id)
    if document = Document.find_by_id(document_id)
      document.clean_rich_text_segments
      document.save if document.changed.include?("rich_text")
    end
  end
end
