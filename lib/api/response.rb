class Api::Response
  attr_accessor :code, :options, :data, :http_status, :deprecated
  attr_reader   :messages

  # To satisfy rails serialization
  def self.model_name
    @model_name ||= ::ActiveModel::Name.new(self, nil)
  end

  def initialize(data = nil)
    cleanup
    error(data) if data
  end

  def cleanup
    self.code    = 0 # TODO Api::Code::SUCCESS
    @messages    = []
    self.data    = {}
    self.options = {:root => nil, :skip_types => true, :indent => 0, :dasherize => false}
  end

  def add_data(value)
    self.data = self.data.merge(value)
  end

  def error(exception)
    if exception.is_a?(Exception)
      self.code        = Api::Code.code_for(exception)
      self.http_status = Api::Code.http_status_for(exception)
      self.messages    = Api::Code.message_for(exception)
=begin
    elsif exception.is_a?(Api::Exception)
      self.code        = exception.code
      self.http_status = exception.http_status
      self.messages    = exception.message
=end
    end
  end

  def to_xml(options = {})
    prepare_data
    options.reverse_merge!(self.options)
    self.data.to_xml(options) 
  end

  # Note: This isn't the best implementation but there are currently no ruby JSON builders that append raw
  # JSON string objects like XML builder. They tend to favor parsing the JSON and coverting it to a ruby hash
  # to be combined and modified and later rendering JSON again.
  def to_json(options = {})
    prepare_data
    result = self.data.map do |key, value|
      %{"#{key}": #{value.to_json(options)}}
    end.join(",")
    "{\"#{self.options[:root]}\": {#{result}}}"
  end

  def messages=(value)
    if value.is_a?(String)
      @messages << value
    elsif value.is_a?(Array)
      @messages = (@messages + value).flatten.uniq
    end
  end

  private
  
  def prepare_data
    data[:code]    = self.code
    options[:root] = code < 0 ? "error" : "unknown"
    # TODO self.messages = [Api::Code.get_message(self.code)] if @messages.blank? || deprecated
    data.each_value { |value| self.messages = value.messages if value.respond_to?(:messages) }
    data[:messages] = self.messages
  end
end

# To satisfy rails respond_with
def api_response_url *params
  ''
end
