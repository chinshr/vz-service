class Upload < ActiveRecord::Base
  has_one :ingest, dependent: :destroy
  belongs_to :session
  
  validates :type, presence: true
  validates :file_name, presence: true, length: { maximum: 255 }
  validates :file_type, presence: true, length: { maximum: 255 }
  validates :s3_url, presence: true, length: { maximum: 255 }

  scope :any_of_states, lambda {|params| joins(:ingest).where(:ingests => {:aasm_state => [params].flatten.map(&:to_s)})}
  scope :none_of_states, lambda {|params| joins(:ingest).where("ingests.aasm_state NOT IN (?)", [params].flatten.map(&:to_s)) }
  scope :started, lambda {any_of_states(:started)}
  scope :stopped, lambda {any_of_states(:stopped)}
  scope :reset, lambda {any_of_states(:reset)}
  scope :removed, lambda {any_of_states(:removed)}
  scope :finished, lambda {any_of_states(:finished)}
  scope :recent, lambda {|n = 5| order("uploads.created_at DESC").limit(n)}
  
  class << self
    
    # type casts to the class specified in :type parameter
    #
    # E.g.
    #
    #   Account::Activity.new(:type => :media_view, ...) -> Account::Activity::MediaView
    #   Account::Activity.create(:type => "Account::Activity::MediaView", ...) -> Account::Activity::MediaView
    #   Account::Activity.new(:type => :favorite, :media_id => 1) -> Account::Activity::MediaFavorite
    #   Account::Activity.new(:type => :favorite, :subject => @media) -> Account::Activity::MediaFavorite
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
    result = file_name
    return if result.blank?
    result = result.split(".").first unless result.blank?
    result.gsub!(/[-+]+/, ' ') unless result.blank?
    result = result.humanize unless result.blank?
    result
  end
  
  def s3_key
    s3_url ? s3_url.split("/").last : nil
  end
  
  def has_s3_url?
    !s3_url.blank?
  end
end
