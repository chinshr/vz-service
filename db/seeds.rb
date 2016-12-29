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

# Koudoku Plans

@personal_plan = Plan.find_or_initialize_by(name: 'Personal')
if @personal_plan.new_record?
  @personal_plan.price = 9.00
  @personal_plan.interval = 'month'
  @personal_plan.stripe_id = '10'
  @personal_plan.features = ['5 media per month', 'Up to 30 min. per media', 'Normal quality', '1 User', '**Private** and **public** files'].join("\n\n")
  @personal_plan.display_order = 1
  @personal_plan.save!
end

@personal_plan = Plan.find_or_initialize_by(name: 'Professional')
if @personal_plan.new_record?
  @personal_plan.price = 35.00
  @personal_plan.interval = 'month'
  @personal_plan.stripe_id = '20'
  @personal_plan.features = ['10 media per month', 'Up to 60 min. per media', 'High quality', '1 User', '**Private** and **public** files'].join("\n\n")
  @personal_plan.display_order = 2
  @personal_plan.save!
end

@personal_plan = Plan.find_or_initialize_by(name: 'Enterprise')
if @personal_plan.new_record?
  @personal_plan.price = 995.00
  @personal_plan.interval = 'month'
  @personal_plan.stripe_id = '30'
  @personal_plan.features = ['20 media per month', 'Up to 90 min. per media', 'Highest quality', '10 Users', '**Private** and **public** files'].join("\n\n")
  @personal_plan.display_order = 3
  @personal_plan.save!
end
