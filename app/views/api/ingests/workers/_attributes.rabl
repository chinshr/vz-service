attributes :id, :uid, :ingest_iteration, :worker_name, :state, :status,
  :ingest_id, :server_id, :instance_id, :messages, :progress, :created_at,
  :started_at, :stopped_at, :finished_at, :lock_count, :worker_object_id

child({:ingest => "ingest"}, unless: -> (m) { action_name == "index" }) {
  extends "api/ingests/attributes"
}
