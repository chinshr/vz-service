module Provider; end
module Provider::AWS; end

Dir[File.dirname(__FILE__) + "/provider/**/*.rb"].each {|file| require file}