class Plan::Config
  include Model::Virtus::ActiveModel

  VERSION = "1.0.0"

  # attribute :version, String, default: :current_version, lazy: true
  complex_attribute :transcription, Plan::Config::Transcription, default: {}
  complex_attribute :quotas, Plan::Config::Quotas, default: {}

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
