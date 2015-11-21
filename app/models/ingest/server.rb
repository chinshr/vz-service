class Ingest::Server < ActiveRecord::Base
  include AASM
  include Model::AASM::Support
  include Model::Uid

  self.table_name = "ingest_servers"
  self.uid_length = 5

  STATE_PENDING   = 0
  STATE_ENABLED   = 1
  STATE_DISABLED  = 2
  STATES = {pending: STATE_PENDING,
    enabled: STATE_ENABLED, disabled: STATE_DISABLED}

  TENANCY_SHARED   = 0
  TENANCY_PRIVATE  = 1
  TENANCY_SETTINGS = {'shared' => TENANCY_SHARED, 'private' => TENANCY_PRIVATE}

  has_many :processes, class_name: "Ingest::Process", dependent: :destroy
  has_many :ingests, through: :processes, after_remove: :async_server_update

  validates :max_processes, numericality: true

  scope :available, -> (tenancy = :shared) {
    select("ingest_servers.*, (SELECT COUNT(ingest_processes.id) FROM ingest_processes WHERE ingest_processes.server_id = ingest_servers.id) AS processes_count, (ingest_servers.max_processes - (SELECT COUNT(ingest_processes.id) FROM ingest_processes WHERE ingest_processes.server_id = ingest_servers.id)) AS available_processes_count")
      .enabled
      .with_tenancy(tenancy)
      .having("(max_processes - (SELECT COUNT(ingest_processes.id) FROM ingest_processes WHERE ingest_processes.server_id = ingest_servers.id)) > 0")
      .group("ingest_servers.id")
      .order("available_processes_count DESC")
  }
  scope :with_tenancy, -> (tenancy) {
    where("ingest_servers.tenancy_mask & #{tenancy_mask(tenancy)} > 0")
  }
  scope :without_processes, -> {
    select("ingest_servers.*, (SELECT COUNT(ingest_processes.id) FROM ingest_processes WHERE ingest_processes.server_id = ingest_servers.id) AS processes_count")
      .having("(SELECT COUNT(ingest_processes.id) FROM ingest_processes WHERE ingest_processes.server_id = ingest_servers.id) = 0")
      .group("ingest_servers.id")
  }

  aasm column: 'aasm_state' do
    state :pending, initial: true
    state :enabled, :enter => :enter_enabled
    state :disabled, :enter => :enter_disabled

    event :enable do
      transitions :from => [:pending, :enabled], :to => :enabled
    end

    event :disable do
      transitions :from => [:pending, :enabled, :disabled], :to => :disabled
    end
  end

  before_destroy :terminate

  class << self

    def create_from(instance, attributes = {})
      attributes = {tenancy: 'shared'}.reverse_merge(attributes)
      # http://www.rubydoc.info/gems/aws-sdk-v1/1.66.0/AWS/EC2/Instance
      find_or_create_by!(instance_id: instance.id) do |server|
        # server.instance_id        = instance.id
        # server.name               = instance.name
        # server.region             = instance.region
        server.vpc_id             = instance.vpc_id
        server.public_ip_address  = instance.public_ip_address  # e.g. "52.23.218.241"
        server.private_ip_address = instance.private_ip_address  # e.g. "172.30.0.82"
        server.launched_at        = instance.launch_time
        server.image_id           = instance.image_id # -> "ami-8fcbb0ea"
        server.instance_type      = instance.instance_type || "t2.micro" # -> "t2.micro"
        # calculated fields
        server.number             = next_number
        server.max_processes      = max_processes_from(server.instance_type)
        # assign attributes
        attributes.each do |k, v|
          server.send("#{k}=", v)
        end
      end
    end

    def next_number
     (maximum(:number) || 0) + 1
    end

    # https://aws.amazon.com/ec2/instance-types/
    def max_processes_from(instance_type)
      type, size = instance_type.split('.')
      base = case type
      when 't2' then 2
      when 'm4', 'm3' then 8
      when 'c3', 'c4' then 4
      else
        1
      end

      multiplier = case size
      when 'micro' then 1
      when 'small' then 2
      when 'medium' then 4
      when 'large' then 8
      when 'xlarge' then 16
      when '2xlarge' then 32
      when '4xlarge' then 64
      when '10xlarge' then 128
      else
        1
      end

      base * multiplier
    end

    def tenancy_mask(number)
      numbers = TENANCY_SETTINGS.map {|k,v| number.is_a?(Fixnum) ? v : k}
      index   = numbers.index(number.is_a?(Fixnum) ? number : number.to_s)
      index ? 2**index : 0
    end

  end

  def has_vpc?
    !!instance.vpc_id
  end

  def tenancy=(values)
    self.tenancy_mask = ([values].flatten.map(&:to_s) & TENANCY_SETTINGS.keys).sum {|d| self.class.tenancy_mask(d)}
  end

  def tenancy
    TENANCY_SETTINGS.keys.reject {|d| ((tenancy_mask || 0) & self.class.tenancy_mask(d)).zero?}
  end

  def stats
    Provider::AWS::CloudWatch.new(self.region).get_ec2_stats(instance)
  end

  def instance
    AWS.config(region: self.region) unless AWS.config.region == self.region
    @instance ||= Provider::AWS::EC2.new(instance_id: self.instance_id).instance
  end

  def status
    instance.status
  end

  def restart
    ::Ingest::Server::RestartJob.perform_later(self.id)
  end

  def stop
    ::Ingest::Server::StopJob.perform_later(self.id)
  end

  def terminate
    ::Ingest::Server::TerminateJob.perform_later(self.id)
  end

  protected

  def test?
    Rails.env.development?
  end

  def _restart
    case instance.status
    when :running, :pending
      enable!
    when :terminated, :shutting_down
      false
    when :stopping
      wait_until(:stopped)
      _restart
    when :stopped
      instance.start unless test?
      enable!
    end
  end

  def _stop
    case instance.status
    when :running
      instance.stop unless test?
      true
    when :pending
      wait_until(:running)
      _stop
    when :terminated, :shutting_down
      false
    when :stopping, :stopped
      true
    end
  end

  def _terminate
    disable!
    case instance.status
    when :running
      instance.terminate unless test?
      true
    when :pending
      wait_until(:running)
      _terminate
    when :terminated, :shutting_down
      true
    when :stopping
      wait_until(:stopped)
      _terminate
    when :stopped
      instance.terminate unless test?
      true
    end
  end

  def wait_until(status)
    return true if test?
    wait_time = 2.minutes
    while wait_time > 0
      puts "Waiting for instance to #{status}...#{instance.id}, status: #{instance.status}"
      sleep(30)
      wait_time = wait_time - 30
      break if instance.status == status
    end
    raise "EC2 instance failed to #{status} in appropriate time!" if wait_time <= 0
    true
  end

  def async_server_update(record = nil)
    stop if ingests.count == 0
  end

  def enter_enabled
    self.enabled_at = Time.zone.now
  end

  def enter_disabled
    self.disabled_at = Time.zone.now
  end
end
