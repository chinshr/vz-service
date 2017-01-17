class User::Properties
  include Model::Virtus::ActiveModel

  VERSION = "1.0.0"

  attribute :version, String, default: :current_version, lazy: true

  complex_attribute :config, Plan::Config, default: {}
  attribute :css_hex_color, String

  def self.dump(values)
    values = values.is_a?(String) ? JSON.parse(values) : values
    values.to_hash
  end

  def self.load(values)
    new(values)
  end

  private

  def current_version
    VERSION
  end
end
