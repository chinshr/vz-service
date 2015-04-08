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
