class AddRestartedAtToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :restarted_at, :datetime
  end
end
