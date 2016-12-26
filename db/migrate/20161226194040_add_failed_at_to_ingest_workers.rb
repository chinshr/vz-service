class AddFailedAtToIngestWorkers < ActiveRecord::Migration
  def change
    add_column :ingest_workers, :failed_at, :datetime
    add_index :ingest_workers, :failed_at
  end
end
