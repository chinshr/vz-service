class CreateSessions < ActiveRecord::Migration
  def change
    create_table :sessions do |t|
      t.string   :uid
      t.string   :ip
      t.string   :user_agent
      t.timestamps
    end
    add_index :sessions, :uid
  end
end
