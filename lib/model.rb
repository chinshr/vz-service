module Model; end
module Model::User; end
module Model::AASM; end

Dir[File.dirname(__FILE__) + "/model/**/*.rb"].each {|file| require file}
