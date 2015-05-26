class RenameTableTrackingsToSegments < ActiveRecord::Migration
  def up
    rename_table :trackings, :segments
  end

  def down
    rename_table :segments, :trackings
  end
end
