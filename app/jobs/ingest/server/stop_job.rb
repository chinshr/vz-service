class Ingest::Server::StopJob < ActiveJob::Base
  include Job::Helper
  queue_as :default

  def perform(server_id)
    if @server = Ingest::Server.find_by(id: server_id)
      @server.with_lock do
        @server.send(:_stop) if @server.ingests.count == 0
      end
    end
  end
end