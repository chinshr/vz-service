module Api; end
Dir[File.dirname(__FILE__) + "/api/**/*.rb"].each {|file| require file}
