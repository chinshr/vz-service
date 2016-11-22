# Loads the config/app.yml file values into APP_CONFIG
# Based off of the rails env.
APP_CONFIG = YAML.load(ERB.new(File.read("#{Rails.root}/config/app.yml")).result)[Rails.env]
