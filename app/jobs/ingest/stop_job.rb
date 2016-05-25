class Ingest::StopJob < Ingest::ProcessJob

  def perform(ingest_id, options = {})
    stop_all_running_workers(ingest_id)
    super(ingest_id, options)
  end

  protected

  def stop_all_running_workers(ingest_id)
    Ingest::Worker.active.ingest_id(ingest_id).find_each {|w| w.stop! if w.may_stop?}
  end
end