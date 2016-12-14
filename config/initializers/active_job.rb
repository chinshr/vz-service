ActiveJob::Base.queue_adapter = case Rails.env
  when 'production' then ENV.fetch('ACTIVE_JOB_QUEUE_ADAPTER', :sidekiq).to_sym
  else
    ENV.fetch('ACTIVE_JOB_QUEUE_ADAPTER', :inline).to_sym
end
