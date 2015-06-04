class Ingest::StartWorker < Worker::Ingest::Base
  self.workflow_stage_id = 100
end