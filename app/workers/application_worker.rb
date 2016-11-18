class ApplicationWorker
  attr_accessor :params
  cattr_accessor :queues
  cattr_accessor :sqs

  class << self
    def perform_async(params = {})
      new.perform(params)
    end
    alias_method :perform_later, :perform_async

    def perform_workflow(ingest_id, params = {})
      new.perform({ingest_id: ingest_id, workflow: true}.reverse_merge(params))
    end

    def queue_name
      tokens = name.split("::")
      tokens = tokens.map {|t| t.underscore.gsub(/_worker/, "").upcase }
      "#{tokens.join('_')}_#{Rails.env.upcase}_QUEUE"
    end

    def queue(name = queue_name)
      self.sqs ||= AWS::SQS.new
      self.queues = {} unless queues.present?
      # queues[name.to_sym] ||= sqs.queues.named(name)
      sqs.queues.named(name)
    end
  end  # class methods

  def perform(attributes = {})
    result, ingest_id, worker = nil, nil, nil
    self.params = attributes.clone
    Rails.logger.info "+++ ApplicationWorker#perform (#{self.class.name}#perform) begin with #{params.inspect}"
    if ingest_id = params[:ingest_id]
      worker = ::Ingest::Worker.create(ingest_id: ingest_id, worker_name: self.class.name.underscore)
      self.params.reverse_merge!({worker_id: worker.id}) if worker.persisted?
    end
    Rails.logger.info "+++ ApplicationWorker#perform (#{self.class.name}#perform) after ::Ingest::Worker.create(ingest_id: #{ingest_id}, worker_id=#{worker.id}) with #{params.inspect}"
    result = queue.send_message(params.to_json)
    Rails.logger.info "+++ ApplicationWorker#perform (#{self.class.name}#perform) after queue.send_message with #{params.inspect}"
  rescue Exception => ex
    Rails.logger.info "+++ ApplicationWorker#perform (#{self.class.name}#perform) error caught '#{ex.message}', backtrace: #{ex.backtrace}"
  ensure
    result
  end

  protected

  def queue_name
    self.class.queue_name
  end

  def queue(name = queue_name)
    self.class.queue(name)
  end
end
