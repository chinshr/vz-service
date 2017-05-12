class Document::UpdateRichTextJob < ApplicationJob
  queue_as :default

  def perform(document_id, rich_text = {})
    document = Document.find(document_id)
    document.send(:update_chunks_from, rich_text) unless rich_text.empty?
  end
end
