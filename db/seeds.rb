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
@cpw_client = Api::Client.find_or_initialize_by(key: "dOgP7wlYPtra19IeFzOMmI0nxfYekuCkI2sXrLNzSgcc")
if @cpw_client.new_record?
  @cpw_client.name = "CPW"
  @cpw_client.save!
end

# iPhone client
@iphone_client = Api::Client.find_or_initialize_by(key: "J1K58YcsAKf9QXDxVi5yn8yqzqEtNkzstz7xqx2AZYgr")
if @iphone_client.new_record?
  @iphone_client.name     = "iPhone"
  @iphone_client.platform = @iphone_platform
  @iphone_client.save!
end