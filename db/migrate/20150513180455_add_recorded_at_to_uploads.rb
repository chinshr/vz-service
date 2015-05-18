class AddRecordedAtToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :recorded_at, :datetime
  end
end
