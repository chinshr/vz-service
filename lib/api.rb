module Api; end

require "api/exception"
Dir[File.dirname(__FILE__) + "/api/**/*.rb"].each {|file| require file}
