Dir["#{Rails.root}/app/models/chunk/**/*.rb"].each do |file|
  require_dependency file
end
