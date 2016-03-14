class Ingest::Server::StopJob < ActiveJob::Base
  include Job::Helper
  queue_as :default

  def perform(server_id)
    if @server = Ingest::Server.find_by(id: server_id)
      @server.with_lock do
        if @server.without_running_processes?
          @server.send(:_stop)
        end
      end
    end
  end
end