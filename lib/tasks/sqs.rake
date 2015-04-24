namespace :sqs do
  namespace :queues do
    desc "Create queues"
    task :create => :environment do
      AWS.config(
        :access_key_id     => APP_CONFIG['S3_KEY'],
        :secret_access_key => APP_CONFIG['S3_SECRET']
      )
      sqs = AWS::SQS.new
      Ingest::STAGES.select {|k,v| v > 0}.keys.each do |stage|
        queue_name = Ingest.queue_name_from(stage)
        puts "Creating '#{queue_name}' queue."
        queue = sqs.queues.create(queue_name)
      end
    end
  end
end