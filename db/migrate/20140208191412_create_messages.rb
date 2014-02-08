class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string   :uid, null: false
      t.string   :from
      t.string   :to
      t.string   :cc
      t.string   :reply_to
      t.string   :subject
      t.text     :html
      t.text     :text
      t.text     :attachments
      t.string   :type
      t.timestamps
    end
    
    add_index :messages, :uid
    add_index :messages, :type
  end
end
