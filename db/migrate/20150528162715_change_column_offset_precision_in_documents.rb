class ChangeColumnOffsetPrecisionInDocuments < ActiveRecord::Migration
  def up
    change_column :documents, :offset, :decimal, precision: 15, scale: 3
  end

  def down
    change_column :documents, :offset, :decimal, precision: 11, scale: 5
  end
end
