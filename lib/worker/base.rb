class Worker::Base
  class << self

    def perform_async(params = {})
      sqs   = AWS::SQS.new
      queue = sqs.queues.named(queue_name)
      queue.send_message(params.to_json)
    end

    def perform_workflow(params = {})
      perform_async(params.reverse_merge(workflow: true))
    end

    def queue_name
      nm  = name.split("::").last.underscore.gsub(/_worker/, "").upcase
      env = Rails.env.upcase
      "#{nm}_#{env}_QUEUE"
    end

  end
end