class AddMetaDataToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :metadata, :json, null: false, default: {}
  end
end
