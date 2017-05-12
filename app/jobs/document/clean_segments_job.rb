class Document::CleanSegmentsJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    if document = Document.find_by_id(document_id)
      document.clean_rich_text_segments
      document.clean_html_segments
      document.save if document.changed.include?("rich_text") || document.changed.include?("html")
    end
  end
end
