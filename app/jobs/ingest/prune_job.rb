class Ingest::PruneJob < ActiveJob::Base
  queue_as :default

  def perform
    # stale ingests should be stopped
    Ingest.starting.where("ingests.created_at < ?", Time.zone.now - 1.hour)
      .find_each do |ingest|
        # force stop ingest, which in turn will
        # stop the server if no other ingests are
        # scheduled.
        ingest.fail!
    end

    # removing: terminated and not busy
    Ingest.removing.is_terminated(true).is_busy(false).find_each do |ingest|
      ingest.process!
    end

    # removed: TODO: not necessary.
    Ingest.removed.find_each do |ingest|
      ingest.send(:after_enter_removed)
    end

    # resetting: terminated and not busy
    Ingest.resetting.is_terminated(true).is_busy(false).find_each do |ingest|
      ingest.process!
    end

    # stale servers should be terminated
    Ingest::Server.enabled.without_processes
      .where("ingest_servers.enabled_at < ?", Time.zone.now - 1.hour)
      .find_each do |server|
        server.terminate
    end
  end
end