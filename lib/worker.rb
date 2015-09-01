module Worker; end
module Worker::Ingest; end

require "worker/base"
Dir[File.dirname(__FILE__) + "/worker/**/*.rb"].each {|file| require file}