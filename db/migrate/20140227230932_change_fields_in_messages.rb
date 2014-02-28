class ChangeFieldsInMessages < ActiveRecord::Migration
  def up
    change_column :messages, :to, :text
    change_column :messages, :cc, :text
  end

  def down
    change_column :messages, :to, :string
    change_column :messages, :cc, :string
  end
end
