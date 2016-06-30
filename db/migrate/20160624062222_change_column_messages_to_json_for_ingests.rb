class ChangeColumnMessagesToJsonForIngests < ActiveRecord::Migration
  def up
    remove_column :ingests, :messages
    add_column :ingests, :messages, :json, null: false, default: {}
  end

  def down
    remove_column :ingests, :messages
    add_column :ingests, :messages, :text
  end
end
