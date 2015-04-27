attributes :id, :mp3_stream_url, :created_at
if current_user.try(:backend_role?)
  attributes :uid, :s3_url, :updated_at
end