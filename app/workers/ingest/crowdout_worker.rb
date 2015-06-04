class Ingest::CrowdoutWorker < Worker::Ingest::Base
  self.workflow_stage_id = 500
end