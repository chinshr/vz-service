class Worker::Base
  attr_accessor :params
  cattr_accessor :queues
  self.queues = {}

  class << self

    def perform_async(params = {})
      new.perform(params)
    end
    alias_method :perform_later, :perform_async

    def perform_workflow(params = {})
      new.perform(params.reverse_merge(workflow: true))
    end

    def queue_name
      tokens = name.split("::")
      tokens = tokens.map {|t| t.underscore.gsub(/_worker/, "").upcase }
      "#{tokens.join('_')}_#{Rails.env.upcase}_QUEUE"
    end

    def queue(name = queue_name)
      @@sqs ||= AWS::SQS.new
      queues[name.to_sym] ||= @@sqs.queues.named(name)
    end
  end  # class methods

  def perform(params = {})
    self.params = params
    queue.send_message(params.to_json)
  end

  protected

  def queue_name
    self.class.queue_name
  end

  def queue(name = queue_name)
    self.class.queue(name)
  end
end
