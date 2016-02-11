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

  validates :document, presence: true
  validates :upload, presence: true, on: :create

  def use_source_annotations=(value)
    self[:use_source_annotations] = Model::Helper.booleanize(value)
  end

end
