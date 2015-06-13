class Worker::Base
  attr_accessor :params
  cattr_accessor :queues
  self.queues = {}

  class << self

    def perform_async(params = {})
      new.perform(params)
    end

    def perform_workflow(params = {})
      new.perform(params.reverse_merge(workflow: true))
    end

    def queue_name
      nm  = name.split("::").last.underscore.gsub(/_worker/, "").upcase
      env = Rails.env.upcase
      "#{nm}_#{env}_QUEUE"
    end

    def queue(name = queue_name)
      @@sqs ||= AWS::SQS.new
      queues[name.to_sym] ||= @@sqs.queues.named(name)
    end
  end  # class methods

  def perform(params = {})
    self.params = params
    # TODO: find a better way to stub SQS call
    queue.send_message(params.to_json)# unless Rails.env.test?
  end

  protected

  def queue_name
    self.class.queue_name
  end

  def queue(name = queue_name)
    self.class.queue(name)
  end
end