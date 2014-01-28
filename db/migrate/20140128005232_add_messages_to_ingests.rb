class AddMessagesToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :messages, :text
  end
end
