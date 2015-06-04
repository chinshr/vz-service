class Worker::Ingest::Base < Worker::Base

  class << self
    attr_accessor :workflow_stage_id

    def perform_async(ingest_id, options = {})
      super({ingest_id: ingest_id}.reverse_merge(options))
    end

    def perform_workflow(ingest_id, options = {})
      super({ingest_id: ingest_id}.reverse_merge(options))
    end

    def stage_name
      name.split("::").last.underscore.gsub(/_worker/, "").to_sym
    end

  end
end