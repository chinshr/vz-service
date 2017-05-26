# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
@admin_user = AdminUser.find_or_initialize_by(email: 'manager@voyz.es')
if @admin_user.new_record?
  @admin_user.password              = 'paloalto605:voyzes'
  @admin_user.password_confirmation = 'paloalto605:voyzes'
  @admin_user.save!
end

@cpw_user = User.find_or_initialize_by(email: "cpw@voyz.es")
if @cpw_user.new_record?
  @cpw_user.skip_registration_validation = true
  @cpw_user.first_name            = 'Content P.'
  @cpw_user.last_name             = 'Workflow'
  @cpw_user.username              = 'cpw'
  @cpw_user.password              = 'paloalto605:voyzescpw'
  @cpw_user.password_confirmation = 'paloalto605:voyzescpw'
  @cpw_user.roles                 = [:backend]
  @cpw_user.confirmed_at          = Time.zone.now
  @cpw_user.save!
end

require_relative "seeds/image_formats"

#--- API platforms
# generic web
@web_platform = Api::Platform.find_or_initialize_by(uid: "qqiSCNKn")
if @web_platform.new_record?
  @web_platform.name    = "Web"
  @web_platform.version = "all"
  @web_platform.save!
  @web_platform.activate!
end

# iPhone platform
@iphone_platform = Api::Platform.find_or_initialize_by(uid: "CDI344o0")
if @iphone_platform.new_record?
  @iphone_platform.name    = "iPhone"
  @iphone_platform.version = "1.0"
  @iphone_platform.save
  @iphone_platform.activate!
end

#--- API clients
# CPW client
@cpw_client = Api::Client.find_or_initialize_by(name: "CPW")
if @cpw_client.new_record?
  @cpw_client.key = "dOgP7wlYPtra19IeFzOMmI0nxfYekuCkI2sXrLNzSgcc"
  @cpw_client.save!
end

# iPhone client
@iphone_client = Api::Client.find_or_initialize_by(name: "iPhone")
if @iphone_client.new_record?
  @iphone_client.key      = "J1K58YcsAKf9QXDxVi5yn8yqzqEtNkzstz7xqx2AZYgr"
  @iphone_client.platform = @iphone_platform
  @iphone_client.save!
end

# Model Trainer (MT) client
@mt_client = Api::Client.find_or_initialize_by(name: "MT")
if @mt_client.new_record?
  @mt_client.key = "Srur1MOdW71ONKK5IY4b88KLTEjzyCYv4Fay2GYWpnM4"
  @mt_client.save!
end

# Subscription plans

personal_month_1500 = Plan.where(stripe_id: 'personal_month_1500').first_or_initialize do |p|
  p.name          = "Personal"
  p.key           = "personal_month"
  p.amount        = 1500
  p.interval      = 'month'
  p.display_order = 10
  p.enabled       = true
  p.visible       = true
  p.create_stripe = true
  p.config.transcription.quality = "high"
  p.config.quotas.minutes_per_user = 120
  p.config.quotas.minutes_per_user_interval = 'month'
end
personal_month_1500.save! if personal_month_1500.changed?

professional_month_4000 = Plan.where(stripe_id: 'professional_month_4000').first_or_initialize do |p|
  p.name          = "Professional"
  p.key           = "professional_month"
  p.amount        = 4000
  p.interval      = 'month'
  p.display_order = 20
  p.highlight     = "popular"
  p.enabled       = true
  p.visible       = true
  p.create_stripe = true
  p.config.transcription.quality = "highest"
end
professional_month_4000.save! if professional_month_4000.changed?

team_month_9900 = Plan.where(stripe_id: "team_month_9900").first_or_initialize do |p|
  p.name          = "Team"
  p.key           = "team_month"
  p.amount        = 9900
  p.interval      = 'month'
  p.display_order = 30
  p.highlight     = "coming_soon"
  p.enabled       = false
  p.visible       = true
  p.create_stripe = true
  p.config.transcription.quality = "highest"
end
team_month_9900.save! if team_month_9900.changed?

enterprise_month_99500 = Plan.where(stripe_id: 'enterprise_month_99500').first_or_initialize do |p|
  p.name          = "Enterprise"
  p.key           = "enterprise_month"
  p.amount        = 99500
  p.interval      = 'month'
  p.display_order = 40
  p.enabled       = false
  p.visible       = false
  p.create_stripe = false
  p.config.transcription.quality = "highest"
end
enterprise_month_99500.save! if enterprise_month_99500.changed?
