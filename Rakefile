# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Voyzes::Application.load_tasks

namespace :test do
  task :run => ['test:units', 'test:functionals', 'test:generators', 'test:integration', 'test:lib', 'test:jobs', 'test:workers']

  Rake::TestTask.new(lib: "test:prepare") do |t|
    t.libs << "test"
    t.warning = false
    t.pattern = 'test/lib/**/*_test.rb'
  end

  Rake::TestTask.new(jobs: "test:prepare") do |t|
    t.libs << "test"
    t.warning = false
    t.pattern = 'test/jobs/**/*_test.rb'
  end

  Rake::TestTask.new(workers: "test:prepare") do |t|
    t.libs << "test"
    t.warning = false
    t.pattern = 'test/workers/**/*_test.rb'
  end
end

task default: :test

desc "Deploy to heroku"
task :deploy do
  `git push heroku master`
  `heroku ps:restart worker.1 --app voyzes`
  `heroku ps:restart clock.1 --app voyzes`
  `heroku run rake db:migrate --app voyzes`
end