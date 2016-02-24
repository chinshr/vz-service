preload_app true    # preloads an application before forking worker processes
worker_processes ENV.fetch('UNICORN_WORKER_PROCESSES', 2) # amount of unicorn workers to spin up
timeout 15          # restarts workers set to 15 seconds as recommended by Heroku
listen ENV['PORT'], :backlog => 25

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
    Rails.logger.info('Disconnected from ActiveRecord')
  end
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
    Rails.logger.info('Connected to ActiveRecord')
  end

  # Three unicorns = 3 connections
  Sidekiq.configure_client do |config|
    config.redis = {size: 1, url: ENV["REDISTOGO_URL"] || "redis://localhost:6379/", namespace: 'sidekiq'}
  end
end
