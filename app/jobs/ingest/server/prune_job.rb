class Ingest::Server::PruneJob < ActiveJob::Base
  queue_as :default

  def perform
    stop_servers_without_ingests
    terminate_stale_ingest_servers
    sync_server_status
    destroy_terminated_servers
  end

  protected

  def destroy_terminated_servers
    Ingest::Server.disabled
      .where("ingest_servers.disabled_at < ?", Time.zone.now - 1.day)
      .find_each do |server|
        server.destroy
    end
  end

  def sync_server_status
    Ingest::Server.enabled.find_each do |server|
      status = server.status
      if status == :terminated
        server.disable!
      end
    end
  end

  def stop_servers_without_ingests
    Ingest::Server.enabled
      .where("ingest_servers.enabled_at < ?", Time.zone.now - 15.minutes)
      .find_each do |server|
        server.with_lock do
          if server.without_running_processes?
            server.processes.destroy_all
            server.stop
          end
        end
    end
  end

  def terminate_stale_ingest_servers
    # enabled without processes
    Ingest::Server.enabled
      .where("ingest_servers.enabled_at < ?", Time.zone.now - 8.hours)
      .find_each do |server|
        server.with_lock do
          if server.without_running_processes?
            server.processes.destroy_all
            server.terminate
          end
        end
    end

    # pending
    Ingest::Server.pending.without_processes.find_each do |server|
      server.terminate
    end
  end

end
