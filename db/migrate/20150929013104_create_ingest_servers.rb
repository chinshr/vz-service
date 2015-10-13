class CreateIngestServers < ActiveRecord::Migration
  def change
    create_table :ingest_servers do |t|
      t.string :type, null: false
      t.string :name
      t.string :version
      t.string :vpc_id
      t.integer :tenancy_mask, default: 0, null: false
      t.integer :number, default: 0, null: false
      t.integer :max_processes, default: 1, null: false
      t.string :private_ip_address
      t.string :public_ip_address
      t.string :instance_id
      t.string :region
      t.string :dns
      t.string :image_id
      t.string :instance_type
      t.datetime :launched_at
      t.timestamps
    end

    add_index :ingest_servers, :type
    add_index :ingest_servers, :name
    add_index :ingest_servers, :version
    add_index :ingest_servers, :vpc_id
    add_index :ingest_servers, :tenancy_mask
    add_index :ingest_servers, :max_processes
    add_index :ingest_servers, :image_id
    add_index :ingest_servers, :instance_type
    add_index :ingest_servers, :launched_at
  end
end
