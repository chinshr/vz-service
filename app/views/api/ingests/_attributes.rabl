child(:track => "track") { extends "api/ingests/tracks/attributes" }
child(:upload => "upload") { extends "api/ingests/uploads/attributes" }
child(:document) { extends "api/documents/attributes" }
attributes :id, :upload_id, :document_id, :type, :status,
  :updated_at, :created_at, :started_at, :stopped_at, :restarted_at, :reset_at,
  :removed_at, :finished_at, :progress, :messages, :stage, :iteration, :busy,
  :terminate, :uid
