module Job; end

Dir[File.dirname(__FILE__) + "/job/**/*.rb"].each {|file| require file}
