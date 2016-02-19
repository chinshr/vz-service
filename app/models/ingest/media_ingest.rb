class Ingest::MediaIngest < Ingest
  include Model::MediaHelper
  include Model::Ingest::MediaStages

  delegate :title, to: :document, allow_nil: true
  delegate :title=, to: :document, allow_nil: true
  delegate :description, to: :document, allow_nil: true
  delegate :description=, to: :document, allow_nil: true
  delegate :tag_list, to: :document, allow_nil: true
  delegate :tag_list=, to: :document, allow_nil: true
  delegate :locale, to: :document, allow_nil: true
  delegate :locale=, to: :document, allow_nil: true
  delegate :privacy, to: :document, allow_nil: true
  delegate :privacy=, to: :document, allow_nil: true
  delegate :slug, to: :document, allow_nil: true
  delegate :slug_id, to: :document, allow_nil: true
  delegate :user, to: :document, allow_nil: true
  delegate :user=, to: :document, allow_nil: true

  validates :document, presence: true, on: :create
  validates :upload, presence: true, on: :create
  validate :valid_media_source_url, on: :create, unless: :has_upload?

  before_validation :set_media_attributes, on: :create
  after_commit :create_image_ingest_from_target, on: :create

  def use_source_annotations=(value)
    self[:use_source_annotations] = Model::Helper.booleanize(value)
  end

  private

  def create_image_ingest_from_target
    if metadata['target'] && metadata['target']['image']
      Ingest::ImageIngest.create({
        ingestable: document,
        source_url: metadata['target']['image']
      }).start!
    end
  end
end
