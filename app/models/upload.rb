class Upload < ActiveRecord::Base
  include Model::Filter

  delegate :privacy, to: :ingest, allow_nil: true
  delegate :privacy=, to: :ingest, allow_nil: true

  delegate :user, to: :ingest, allow_nil: true
  delegate :user=, to: :ingest, allow_nil: true

  delegate :title, to: :ingest, allow_nil: true
  delegate :title=, to: :ingest, allow_nil: true

  delegate :description, to: :ingest, allow_nil: true
  delegate :description=, to: :ingest, allow_nil: true

  delegate :tag_list, to: :ingest, allow_nil: true
  delegate :tag_list=, to: :ingest, allow_nil: true

  delegate :locale, to: :ingest, allow_nil: true
  delegate :locale=, to: :ingest, allow_nil: true

  delegate :events, to: :ingest, allow_nil: true
  delegate :event=, to: :ingest, allow_nil: true

  delegate :status, to: :ingest
  delegate :state, to: :ingest
  delegate :slug, to: :ingest
  delegate :progress, to: :ingest

  has_one :ingest

  validates :type, presence: true
  validates :file_name, presence: true, length: { maximum: 255 }
  validates :file_type, presence: true, length: { maximum: 255 }
  validates :s3_url, presence: true, length: { maximum: 255 }
  validates :title, presence: true, on: :update

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :any_of_status, :none_of_status
  scope :sort_order, lambda {|param|
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    when "created_at"
      order(self.arel_table[:created_at].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, lambda {|param| all.reverse_order if Model::Helper.booleanize(param)}
  scope :any_of_status, lambda {|params| joins(:ingest).where("ingests.aasm_state IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq)}
  scope :none_of_status, lambda {|params| joins(:ingest).where("ingests.aasm_state NOT IN (?)", [params].flatten.map(&:to_s).
    map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq)}
  # private scopes
  scope :started, lambda {any_of_status(Ingest::STATES[:started])}
  scope :stopped, lambda {any_of_status(Ingest::STATES[:stopped])}
  scope :reset, lambda {any_of_status(Ingest::STATES[:reset])}
  scope :removed, lambda {any_of_status(Ingest::STATES[:removed])}
  scope :finished, lambda {any_of_status(Ingest::STATES[:finished])}
  scope :most_recent, lambda {|n = 5| order("uploads.created_at DESC").limit(n)}

  after_initialize :build_ingest_and_ingestable
  before_validation :set_title, on: :create
  after_save :save_ingest_and_ingestable
  after_commit :remove_ingest, on: :destroy

  class << self

    # Type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   Upload.new(:type => :audio, ...) -> Upload::Audio
    #   Upload.create(:type => "Upload::Audio", ...) -> Upload::Audio
    #   Upload.create(:type => Upload::Audio, ...) -> Upload::Audio
    #
    def new_with_cast(*a, &b)
      if (h = a.first).is_a? Hash and (type = h[:type] || h['type']) and
        (k = type.class == Class ? type : promote_upload_class_for(type, h)) != self
        raise NameError, "unknown type for Upload" if !k || !(k < self)
        instance = k.new(*a, &b)
        return instance
      end
      new_without_cast(*a, &b)
    end
    alias_method_chain :new, :cast

    def generate_object_name
      Model::Uid.random_string(10, "a-z, 0-9")
    end

    def humanized_file_name(file_name)
      result = file_name
      return if result.blank?
      result = result.split(".").first unless result.blank?
      result.gsub!(/[-+]+/, ' ') unless result.blank?
      result = result.humanize unless result.blank?
      result
    end

    private

    # E.g. "audio" => Upload::Audio
    def class_for(type)
      class_name = class_name_for(type)
      class_name.constantize if class_name
    end

    # E.g.
    #
    #    "audio" => "Upload::Audio"
    #
    def class_name_for(name)
      class_name = name.to_s.index("::") ? "#{name}" : "Upload::#{(name.to_s.classify)}"
      class_name.constantize.name
    rescue NameError
      nil
    end

    def promote_upload_class_for(name, attributes = {})
      attributes.symbolize_keys! if attributes.respond_to?(:symbolize_keys!)
      klass = class_for(name)
      raise NameError, "unkown Upload subclass '#{name}'" unless klass
      attributes[:type] = klass.name
      klass
    end
  end

  def humanized_file_name
    Upload.humanized_file_name(file_name)
  end

  def s3_key
    s3_url ? s3_url.split("/").last : nil
  end

  def has_s3_url?
    !s3_url.blank?
  end

  def has_locale_recently_changed?
    return !!ingest.ingestable.changes[:locale] if ingest.ingestable
    false
  end

  protected

  def set_title
    self.title = humanized_file_name if title.blank?
  end

  def build_ingest_and_ingestable
    # raise NameError, "Abstract class #{self.class.name} cannot be instantiated, use a subclass instead, e.g. #{Upload::Audio.name}." unless !!self.class.permit_abstract_instance
  end

  def save_ingest_and_ingestable
    if ingest
      locale_changed = has_locale_recently_changed?
      ingest.ingestable.save if ingest.ingestable && ingest.ingestable.changed?
      ingest.save if ingest.changed?

      if !new_record? && has_s3_url?
        if locale_changed
          ingest.restart! if ingest.may_restart?
        else
          ingest.start! if ingest.may_start?
        end
      end
    end
  end

  def remove_ingest
    ingest.remove! if ingest.reload
  end

end
