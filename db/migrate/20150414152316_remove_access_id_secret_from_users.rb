class RemoveAccessIdSecretFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, "access_id"
    remove_column :users, "access_secret"
  end

  def down
    add_column :users, "access_id", :string
    add_column :users, "access_secret", :string
  end
end
