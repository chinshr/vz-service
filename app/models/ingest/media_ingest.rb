class Ingest::MediaIngest < Ingest
  include Model::MediaHelper
  include Model::Ingest::MediaStages

  delegate :title, to: :document
  delegate :title=, to: :document

  delegate :description, to: :document
  delegate :description=, to: :document

  delegate :tag_list, to: :document
  delegate :tag_list=, to: :document

  delegate :locale, to: :document
  delegate :locale=, to: :document

  delegate :privacy, to: :document
  delegate :privacy=, to: :document

  delegate :user, to: :document
  delegate :user=, to: :document

  delegate :slug, to: :document
  delegate :slug_id, to: :document

  before_validation :set_handle, on: :create

  def use_source_annotations=(value)
    self[:use_source_annotations] = Model::Helper.booleanize(value)
  end

  protected

  def set_handle
    self[:handle] ||= begin
      if has_s3_source_url?
        # derive handle from original s3 url
        source_url.split("/").last
      else
        # otherwise, generate a random handle
        chars = [('a'..'z'), ('0'..'9')].map {|i| i.to_a}.flatten
        String.new.tap {|s| 1.upto(20) {|i| s << chars[rand(chars.size - 1)]}}
      end
    end
  end

end
