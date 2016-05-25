class Ingest::Server::StopJob < ActiveJob::Base
  include Job::Helper
  queue_as :default

  def perform(server_id)
    if @server = Ingest::Server.find_by_id(server_id)
      @server.with_lock do
        if @server.without_busy_workers?
          @server.send(:_stop)
        end
      end
    end
  end
end
