class Ingest::Server::RestartJob < ApplicationJob
  include Job::Helper
  queue_as :default

  RETRIES = 5
  WAIT_IN_SECS = 1.seconds

  def perform(server_id = nil, options = {})
    options = options.reverse_merge({retries: RETRIES})
    if server_id
      @server = Ingest::Server.find_by_id(server_id)
    else
      return if Rails.env.development?

      unless @server = Ingest::Server::CPWServer.available.first
        @instance = Provider::AWS::EC2.new.launch(type: "cpw")
        @server   = Ingest::Server::CPWServer.create_from(@instance)
      end
    end

    @server.with_lock do
      unless @server.send(:_restart)
        # starts new server instance
        Ingest::Server::RestartJob.perform_later(nil, {retries: options[:retries] - 1}) if options[:retries] > 0
      end
    end
  end
end
