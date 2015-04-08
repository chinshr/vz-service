class AddAuthenticationTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :access_id, :string
    add_column :users, :access_secret, :string

    add_index :users, :access_id
  end
end
