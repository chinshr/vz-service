class Ingest::ApplicationWorker < ::ApplicationWorker
  class << self

    def perform_async(ingest_id, options = {})
      new.perform({ingest_id: ingest_id}.reverse_merge(options))
    end
    alias_method :perform_later, :perform_async

    def perform_workflow(ingest_id, options = {})
      new.perform({ingest_id: ingest_id, workflow: true}.reverse_merge(options))
    end

  end
end
