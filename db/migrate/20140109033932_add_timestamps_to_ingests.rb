class AddTimestampsToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :started_at, :datetime
    add_column :ingests, :stopped_at, :datetime
    add_column :ingests, :reset_at, :datetime
    add_column :ingests, :removed_at, :datetime
    add_column :ingests, :finished_at, :datetime

    add_index :ingests, :started_at
    add_index :ingests, :stopped_at
    add_index :ingests, :reset_at
    add_index :ingests, :removed_at
    add_index :ingests, :finished_at
  end
end
