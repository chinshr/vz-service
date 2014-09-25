class DropSessions < ActiveRecord::Migration
  def up
    drop_table :sessions
  end
  
  def down
    create_table :sessions do |t|
      t.string   :uid
      t.string   :ip
      t.string   :user_agent
      t.timestamps
    end
    add_index :sessions, :uid
  end
end
