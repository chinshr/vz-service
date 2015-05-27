extends "api/tracks/attributes"
attributes :id, :uid, :ingest_iteration, :s3_key, :s3_url, :s3_mp3_key, :s3_mp3_url, :s3_waveform_json_key, :s3_waveform_json_url, :updated_at
if root_object.is_master?
  attributes :ingest_id, :document_id
end