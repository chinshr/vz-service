require File.expand_path('../config/boot', File.dirname(__FILE__))
require File.expand_path('../config/environment', File.dirname(__FILE__))
require 'clockwork'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  every(15.minutes, 'ingest.prune.job') {
    Ingest::PruneJob.perform_later
  }

  every(10.minutes, 'ingest.worker.prune.job') {
    Ingest::Worker::PruneJob.perform_later
  }

  every(5.minutes, 'ingest.server.prune.job') {
    Ingest::Server::PruneJob.perform_later
  }
end
