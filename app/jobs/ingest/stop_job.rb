class Ingest::StopJob < ActiveJob::Base
  queue_as :default

  RETRIES      = 5
  WAIT_IN_SECS = 1.minute

  def perform(ingest_id, options = {})
    options = options.reverse_merge({retries: RETRIES})
    if @ingest = Ingest.find(ingest_id)
      if @ingest.not_busy?
        @ingest.with_lock do
          @ingest.process!
        end
      else
        Ingest::StopJob.set(wait: WAIT_IN_SECS).perform_later(ingest_id, {retries: options[:retries] - 1}) if options[:retries] > 0
      end
    end
  end

end