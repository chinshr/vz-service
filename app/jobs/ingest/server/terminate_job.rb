class Ingest::Server::TerminateJob < ActiveJob::Base
  include Job::Helper
  queue_as :default

  def perform(server_id)
    if @server = Ingest::Server.find_by(id: server_id)
      @server.with_lock do
        @server.send(:_terminate)
      end
    end
  end
end