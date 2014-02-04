# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Voyzes::Application.load_tasks

# Add a new rake test task... E.g., rake test:lib, below everything else in that file...
# Alternatively, add a task in lib/tasks/ directory and plop in the same code
namespace :test do
  desc "Test workers source"
  Rake::TestTask.new(:workers) do |t|
    t.libs << "test"
    t.pattern = 'test/workers/**/*_test.rb'
    t.verbose = true
  end
 
end
 
workers_task = Rake::Task["test:workers"]
test_task = Rake::Task[:test]
test_task.enhance { workers_task.invoke }