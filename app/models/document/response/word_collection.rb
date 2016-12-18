class Document::Response::WordCollection < Array
  include Model::Virtus::Collection

  collection_of Document::Response::Word

  def to_s
    inject("") {|r, el| r += el.meta ? el.word : " #{el.word}"}[1..-1]
  end
end
