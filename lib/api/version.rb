module Api::Version
  MAJOR = "0"
  MINOR = "0"
  TINY  = "1"
  API_VERSION = "#{MAJOR}.#{MINOR}.#{TINY}"
  
  def self.to_s
    "#{MAJOR}.#{MINOR}.#{TINY}"
  end
end