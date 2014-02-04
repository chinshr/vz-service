Voyzes::Application.config.generators do |g|
  g.orm :active_record
  g.test_framework  :test_unit, :fixture => false
end