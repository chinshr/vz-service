class AddInstanceIdToIngestWorkers < ActiveRecord::Migration
  def change
    add_column :ingest_workers, :instance_id, :string
  end
end
