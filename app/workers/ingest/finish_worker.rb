class Ingest::FinishWorker < Worker::Ingest::Base
  self.workflow_stage_id = 700
end