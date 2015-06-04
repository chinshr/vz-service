class Ingest::SplitWorker < Worker::Ingest::Base
  self.workflow_stage_id = 400
end