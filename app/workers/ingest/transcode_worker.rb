class Ingest::TranscodeWorker < Worker::Ingest::Base
  self.workflow_stage_id = 300
end