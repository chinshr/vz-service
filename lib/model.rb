module Model; end
module Model::User; end

Dir[File.dirname(__FILE__) + "/model/**/*.rb"].each {|file| require file}
