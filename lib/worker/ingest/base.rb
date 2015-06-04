class Worker::Ingest::Base < Worker::Base
  class << self

    def perform_async(ingest_id, options = {})
      super({ingest_id: ingest_id}.reverse_merge(options))
    end

    def perform_workflow(ingest_id, options = {})
      super({ingest_id: ingest_id}.reverse_merge(options))
    end

  end
end