class Ingest::Worker::PruneJob < ApplicationJob
  queue_as :default

  def perform
    stop_stale_workers
  end

  protected

  def stop_stale_workers
    Ingest::Worker.running.where("ingest_workers.started_at < ?", Time.zone.now - 3.hour)
      .find_each do |worker|
        worker.stop!
    end
  end

end
