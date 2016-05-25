class RenameMaxProcessesToMaxWorkersForIngestServers < ActiveRecord::Migration
  def up
    rename_column :ingest_servers, :max_processes, :max_workers
  end

  def down
    rename_column :ingest_servers, :max_workers, :max_processes
  end
end
