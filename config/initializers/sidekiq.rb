require 'sidekiq'
# require 'autoscaler/sidekiq'
# require 'autoscaler/heroku_scaler'
# require 'autoscaler/stub_scaler'

# You might need increase the pool size of your AR database, see DB_POOL.

Sidekiq.configure_client do |config|
  # Number of connections per Web dyno, (per Unicorn worker) minimum 1.
  # Only change this value if you query the Redis database more than just for adding tasks to the Sidekiq queue.
  config.redis = {size: 1, url: ENV["REDISTOGO_URL"] || "redis://localhost:6379/", namespace: 'sidekiq'}
  config.logger = nil
  # config.client_middleware do |chain|
  #   if Rails.env.production?
  #     chain.add Autoscaler::Sidekiq::Client, 'default' => Autoscaler::HerokuScaler.new
  #   else
  #     chain.add Autoscaler::Sidekiq::Client, 'default' => Autoscaler::StubScaler.new
  #   end
  # end
end

Sidekiq.configure_server do |config|
  config.redis = {url: ENV["REDISTOGO_URL"] || "redis://localhost:6379/", namespace: 'sidekiq'}

  # config.server_middleware do |chain|
  #   if Rails.env.production?
  #     chain.add(Autoscaler::Sidekiq::Server, Autoscaler::HerokuScaler.new, 60) # 60 second timeout
  #   else
  #     chain.add(Autoscaler::Sidekiq::Server, Autoscaler::StubScaler.new, 60) # 60 second timeout
  #   end
  # end
end