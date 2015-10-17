Rails.application.config.to_prepare do
  Dir["#{Rails.root}/app/models/upload/**/*_upload.rb"].each do |file|
    require_dependency file
  end

  Dir["#{Rails.root}/app/models/ingest/**/*_ingest.rb"].each do |file|
    require_dependency file
  end

  Dir["#{Rails.root}/app/models/chunk/**/*_chunk.rb"].each do |file|
    require_dependency file
  end

  Dir["#{Rails.root}/app/models/track/**/*_track.rb"].each do |file|
    require_dependency file
  end

  Dir["#{Rails.root}/app/workers/**/*_worker.rb"].each do |file|
    require_dependency file
  end
end
