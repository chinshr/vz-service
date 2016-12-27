child(:track => "track") { extends "api/ingests/tracks/attributes" }
attributes :id, :document_id, :ingest_id, :type, :position, :offset,
  :duration, :start_at, :end_at, :text, :score, :response, :processing_status,
  :uid, :ingest_iteration, :locale, :chunk_ids, :processed_stages_mask
