namespace :sqs do
  namespace :queues do
    desc "Create SQS queues"
    task :create => :environment do
      AWS.config(
        :access_key_id     => APP_CONFIG['S3_KEY'],
        :secret_access_key => APP_CONFIG['S3_SECRET']
      )
      sqs = AWS::SQS.new
      Worker::Ingest::Base.subclasses.each do |worker_class|
        queue_name = worker_class.queue_name
        puts "Creating '#{queue_name}' queue."
        queue = sqs.queues.create(queue_name)
      end
    end
  end
end