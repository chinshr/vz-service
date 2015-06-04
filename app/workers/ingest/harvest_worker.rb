class Ingest::HarvestWorker < Worker::Ingest::Base
  self.workflow_stage_id = 200
end