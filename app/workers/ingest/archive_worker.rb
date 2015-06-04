class Ingest::ArchiveWorker < Worker::Ingest::Base
  self.workflow_stage_id = 600
end