class Api::Response
  attr_accessor :code, :options, :data, :http_status, :deprecated
  attr_reader :errors

  class << self
    # To satisfy rails serialization
    def model_name
      @model_name ||= ::ActiveModel::Name.new(self, nil)
    end

    def persisted?; false; end
  end

  def initialize(data = nil)
    cleanup
    add_data(data)
    add_error(data)
  end

  def cleanup
    self.code    = Api::Code::SUCCESS
    @errors      = ActiveSupport::HashWithIndifferentAccess.new
    self.data    = ActiveSupport::HashWithIndifferentAccess.new
    self.options = {root: nil, skip_types: true, indent: 0, dasherize: false}
  end

  def to_model
    self.class
  end

  def to_json(options = {})
    prepare_data
    hash = {code: code}
    if data.present? && self.options[:root]
      hash.merge!({self.options[:root] => data})
    elsif data.present?
      hash.merge!(data)
    end
    hash.to_json
  end

  def to_xml(options = {})
    prepare_data
    options.reverse_merge!(self.options)
    self.data.to_xml(options)
  end

  def add_data(value)
    if value.is_a?(Hash)
      self.data = self.data.merge(value)
    end
    self
  end

  def add_error(error)
    if error.is_a?(Exception)
      self.code          = Api::Code.code_for(error)
      self.http_status   = Api::Code.http_status_for(error)
      base = Array.wrap(self.errors[:base])
      base += Array.wrap(error.message || Api::Code.message_for(error))
      self.data[:base]   = base.reject(&:blank?)
    end
    self
  end

  protected

  def prepare_data
    if data.select {|k, h| h.is_a?(Hash) && h["errors"] && !h["errors"].blank? }.present?
      self.code = Api::Code::VALIDATION_ERROR
    elsif self.code.to_i < 0
      options[:root] = "errors"
    end
  end
end

# To satisfy rails respond_with
def api_response_url(*params)
  ''
end
