require File.expand_path('../config/boot', File.dirname(__FILE__))
require File.expand_path('../config/environment', File.dirname(__FILE__))
require 'clockwork'

module Clockwork
  handler do |job|
    puts "Running #{job}"
  end

  # handler receives the time when job is prepared to run in the 2nd argument
  # handler do |job, time|
  #   puts "Running #{job}, at #{time}"
  # end

  every(15.minutes, 'ingest.prune.job') {
    Ingest::PruneJob.perform_later
  }
end