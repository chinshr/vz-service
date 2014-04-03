class AddTypeAndPositionToSegments < ActiveRecord::Migration
  def change
    add_column :document_segments, :position, :integer
    add_column :document_segments, :type, :string

    add_index :document_segments, :position
    add_index :document_segments, :type
  end
end
