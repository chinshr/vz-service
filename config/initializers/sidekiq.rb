require 'sidekiq'

# You might need increase the pool size of your AR database, see DB_POOL.

Sidekiq.configure_client do |config|
  # Number of connections per Web dyno, (per Unicorn worker) minimum 1.
  # Only change this value if you query the Redis database more than just for adding tasks to the Sidekiq queue.
  config.redis = {:size => 1}
  config.logger = nil
end

# Sidekiq.configure_server do |config|
#   # The config.redis is calculated by the 
#   # concurrency value so you do not need to 
#   # specify this.
#   # config.redis = {:size => 7}
# end