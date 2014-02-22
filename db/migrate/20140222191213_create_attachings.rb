class CreateAttachings < ActiveRecord::Migration
  def change
    create_table :attachings do |t|
      t.integer :message_id
      t.integer :upload_id
      t.timestamps
    end
    add_index :attachings, [:message_id, :upload_id], :unique => true
  end
end
