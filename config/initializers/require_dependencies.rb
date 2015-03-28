Dir["#{Rails.root}/app/models/ingest/chunk/**/*.rb"].each do |file|
  require_dependency file
end
