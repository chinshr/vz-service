# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
AdminUser.find_or_create_by(email: 'manager@voyz.es') do |u|
  u.password              = 'paloalto605:voyzes'
  u.password_confirmation = 'paloalto605:voyzes'
end

User.find_or_create_by(email: "cpw@voyz.es") do |u|
  u.skip_registration_validation = true
  u.password              = 'paloalto605:voyzescpw'
  u.password_confirmation = 'paloalto605:voyzescpw'
  u.roles                 = [:backend]
end

#--- API platforms
# generic web
@web_platform = Api::Platform.find_or_initialize_by(uid: "qqiSCNKn")
if @web_platform.new_record?
  @web_platform.name    = "Web"
  @web_platform.version = "all"
  @web_platform.save
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
  @cpw_client.save
end

# iPhone client
@iphone_client = Api::Client.find_or_initialize_by(key: "J1K58YcsAKf9QXDxVi5yn8yqzqEtNkzstz7xqx2AZYgr")
if @iphone_client.new_record?
  @iphone_client.name     = "iPhone"
  @iphone_client.platform = @iphone_platform
  @iphone_client.save
end