Dir["#{Rails.root}/app/models/document/chunk/**/*.rb"].each do |file|
  require_dependency file
end
