Rails.application.config.to_prepare do
  Dir["#{Rails.root}/app/models/chunk/**/*.rb"].each do |file|
    require_dependency file
  end

  Dir["#{Rails.root}/app/models/track/**/*.rb"].each do |file|
    require_dependency file
  end

  Dir["#{Rails.root}/app/workers/**/*.rb"].each do |file|
    require_dependency file
  end
end
