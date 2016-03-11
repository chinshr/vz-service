class Ingest::MediaIngest::EndJob < ActiveJob::Base
  queue_as :default

  def perform(ingest_id)
    if @ingest = Ingest.find(ingest_id)
      @ingest.fast_forward_stage!
    end
  end
end
