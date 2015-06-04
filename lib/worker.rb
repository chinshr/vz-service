module Worker; end
module Worker::Ingest; end

Dir[File.dirname(__FILE__) + "/worker/**/*.rb"].each {|file| require file}