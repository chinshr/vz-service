class Document::CreateRichTextJob < ActiveJob::Base
  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)
    if document.chunks.count > 0
      document.update_column(:rich_text, document.best_chunks.rich_text)
    end
  end
end
