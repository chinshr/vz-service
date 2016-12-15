class AddLockCountColumnToWorkers < ActiveRecord::Migration
  def change
    add_column :ingest_workers, :lock_count, :integer, null: false, default: 0
  end
end
