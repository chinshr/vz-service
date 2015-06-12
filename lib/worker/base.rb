class Worker::Base
  class << self

    def perform_async(params = {})
      # TODO: find better way to stub SQS call
      unless Rails.env.test?
        sqs   = AWS::SQS.new
        queue = sqs.queues.named(queue_name)
        queue.send_message(params.to_json)
      end
    end

    def perform_workflow(params = {})
      params = params.reverse_merge(workflow: true)
      puts "-> perform_workflow(#{params.inspect})"
      Worker::Base.perform_async(params)
    end

    def queue_name
      nm  = name.split("::").last.underscore.gsub(/_worker/, "").upcase
      env = Rails.env.upcase
      "#{nm}_#{env}_QUEUE"
    end

  end
end