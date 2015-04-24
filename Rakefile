# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Voyzes::Application.load_tasks

namespace :test do
  task :run => ['test:units', 'test:functionals', 'test:generators', 'test:integration', 'test:lib', 'test:workers']
  Rake::TestTask.new(lib: "test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/lib/**/*_test.rb'
  end

  Rake::TestTask.new(workers: "test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/workers/**/*_test.rb'
  end
end

task default: :test
