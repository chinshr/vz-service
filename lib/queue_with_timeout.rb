class QueueWithTimeout
  def initialize
    @mutex = Mutex.new
    @queue = []
    @received = ConditionVariable.new
  end
 
  def push(value)
    @mutex.synchronize do
      @queue << value
      @received.signal
    end
  end
  alias_method :<<, :push
 
  def pop(non_block = false)
    pop_with_timeout(non_block ? 0 : nil)
  end
 
  def pop_with_timeout(timeout = nil)
    @mutex.synchronize do
      if @queue.empty?
        @received.wait(@mutex, timeout) if timeout != 0
        raise ThreadError, "queue empty" if @queue.empty?
      end
      @queue.pop
    end
  end
end
