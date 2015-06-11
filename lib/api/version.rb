module Api::Version
  MAJOR = "2015"
  MINOR = "06"
  TINY  = "01"
  API_VERSION = "#{MAJOR}#{MINOR}#{TINY}"

  def self.to_s
    API_VERSION
  end

  def self.to_date
    Date.parse(API_VERSION)
  end

end