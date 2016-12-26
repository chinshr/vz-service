class AddWorkerObjectIdToIngestWorkers < ActiveRecord::Migration
  def change
    add_column :ingest_workers, :worker_object_id, :string
  end
end
