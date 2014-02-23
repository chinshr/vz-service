class RemoveAttachmentsFromMessages < ActiveRecord::Migration
  def up
    remove_column :messages, :attachments
  end
  
  def down
    add_column :messages, :attachments, :text
  end
end
