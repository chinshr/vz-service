class ChangeSourceUrlToTextInIngests < ActiveRecord::Migration
  def up
    change_column :ingests, :source_url, :text
  end

  def down
    change_column :ingests, :source_url, :string
  end
end
