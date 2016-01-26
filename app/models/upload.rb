class Upload < ActiveRecord::Base
  include Model::Filter
  include Model::Uid
  include Model::S3
  include Wisper::Publisher

  delegate :source_url, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :source_url=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :origin_url, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :handle, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :file_name, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :file_name=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :file_type, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :file_type=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :file_size, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :file_size=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :user, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :user=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :metadata, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :metadata=, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :events, to: :ingest_or_build_ingest_and_associations, allow_nil: true
  delegate :event=, to: :ingest_or_build_ingest_and_associations, allow_nil: true

  delegate :status, to: :ingest_or_build_ingest_and_associations
  delegate :state, to: :ingest_or_build_ingest_and_associations
  delegate :progress, to: :ingest_or_build_ingest_and_associations

  has_one :ingest

  validates_associated :ingest, on: :create
  validates :type, presence: true
  validates :source_url, presence: true, length: { maximum: 2048 }

  # public scopes
  filtered_scopes :sort_order, :reverse_sort, :any_of_status,
    :none_of_status, :any_of_types, :none_of_types
  scope :sort_order, -> (param) {
    case param.first[0]  # E.g. get first key of {"id"=>"asc"}
    when "id"
      order(self.arel_table[:id].send(param.first[1].to_sym).to_sql)
    when "created_at"
      order(self.arel_table[:created_at].send(param.first[1].to_sym).to_sql)
    else
      raise ArgumentError, "Ignored unrecognized value 'sort_order[]=#{param}'."
    end
  }
  scope :reverse_sort, -> (param) { all.reverse_order if Model::Helper.booleanize(param) }
  scope :any_of_status, -> (params) {
    joins(:ingest)
    .where("ingests.aasm_state IN (?)", [params].flatten.map(&:to_s).
      map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq) 
  }
  scope :none_of_status, -> (params) {
    joins(:ingest)
    .where("ingests.aasm_state NOT IN (?)", [params].flatten.map(&:to_s).
      map {|s| s.match(/^([\-]{,1}[0-9]+)$/) ? s : nil}.reject(&:blank?).map {|s| Ingest::STATES.key(s.to_i)}.uniq)
  }
  scope :any_of_types, -> (params) { where("uploads.type IN (?)", class_names_for(params)) }
  scope :none_of_types, -> (params) { where("uploads.type NOT IN (?)", class_names_for(params)) }

  class << self

    # E.g. Upload.descendants -> [Upload::AudioUpload, ..., Upload::MediaUpload]
    def descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    def class_name_from_content_type_for(file_type)
      upload_class = descendants.find {|uc| uc.respond_to?(:accepted_file_type?) && uc.send(:accepted_file_type?, file_type)}
      upload_class.name if upload_class
    end

    # Type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   Upload.new(:type => "media_upload", ...) -> Upload::MediaUpload
    #   Upload.create(:type => "Upload::MediaUpload", ...) -> Upload::MediaUpload
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
      Model::Uid.random_uid_string(10, "a-z, 0-9")
    end

    def generate_uid
      SecureRandom.uuid
    end

    def class_names_for(params)
      Array.wrap(params).map {|p| class_name_for(p)}.reject(&:blank?)
    end

    private

    # E.g. "audio" => Upload::AudioUpload
    def class_for(type)
      class_name = class_name_for(type)
      class_name.constantize if class_name
    end

    # E.g.
    #
    #    "audio_upload" -> "Upload::AudioUpload"
    #    "audio"        -> "Upload::AudioUpload" or
    #
    def class_name_for(name)
      class_name = if name.to_s.index("::")
        "#{name}"
      else
        name.to_s.index("_upload") ? "Upload::#{(name.to_s.classify)}" : "Upload::#{(name.to_s.classify)}Upload"
      end
      class_name.constantize.name
    rescue NameError
      nil
    end

    def promote_upload_class_for(name, attributes = {})
      attributes.symbolize_keys! if attributes.respond_to?(:symbolize_keys!)
      klass = class_for(name)
      raise NameError, "unknown Upload subclass '#{name}'" unless klass
      attributes[:type] = klass.name
      klass
    end
  end

  def destroy_with_ingest_remove
    # Override to remove ingest and assets in job
    ingest.remove! if ingest.reload
    destroy_without_ingest_remove
  end
  alias_method_chain :destroy, :ingest_remove

  def delete_with_job
    Upload::DeleteJob.perform_later(self.id)
  end
  alias_method_chain :delete, :job

  protected

  def ingest_or_build_ingest_and_associations
    ingest ? ingest : build_ingest_and_associations
  end

  def build_ingest_and_associations
    # raise ArgumentError, "implement in subclass"
    build_ingest(upload: self, document: Document.new) unless ingest
  end
end
