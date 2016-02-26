class Ingest::PruneJob < ActiveJob::Base
  queue_as :default

  def perform
    fail_stale_starting_ingests
    process_stale_ingests_in_between_states
    stop_stale_running_ingests
    delete_removed_ingests
    termiante_stale_ingest_servers
  end

  protected

  def fail_stale_starting_ingests
    # ingests stuck in starting should be canceled
    Ingest.starting.where("ingests.created_at < ?", Time.zone.now - 1.hour)
      .find_each do |ingest|
        # force stop ingest, which in turn will
        # stop the server if no other ingests are
        # scheduled.
        ingest.fail!
    end
  end

  def process_stale_ingests_in_between_states
    # re-process 'in between' states, e.g. :starting, etc.
    Ingest.any_of_status([Ingest::STATE_REMOVING, Ingest::STATE_RESETTING, Ingest::STATE_STOPPING]).is_terminated(true).is_busy(false).find_each do |ingest|
      ingest.process!
    end
  end

  def stop_stale_running_ingests
    Ingest.started.is_busy(false).is_terminated(false).where("ingests.created_at < ?", Time.zone.now - 2.hour).find_each do |ingest|
      ingest.stop!
    end
  end

  def delete_removed_ingests
    # delete removed ingests older than 30 days
    Ingest.removed.where("ingests.removed_at < ?", Time.zone.now - 30.days).find_each do |ingest|
      ingest.destroy
    end
  end

  def termiante_stale_ingest_servers
    # stale servers should be terminated
    Ingest::Server.enabled.without_processes
      .where("ingest_servers.enabled_at < ?", Time.zone.now - 24.hours)
      .find_each do |server|
        server.terminate
    end
  end
end
