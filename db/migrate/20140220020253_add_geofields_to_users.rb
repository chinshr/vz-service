class AddGeofieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :lat, :decimal, :precision => 11, :scale => 8
    add_column :users, :lng, :decimal, :precision => 11, :scale => 8

    add_column :users, :time_zone, :string

    add_column :users, :address, :string
    add_column :users, :country_code, :string, :limit => 2
    add_column :users, :city, :string
    add_column :users, :postal_code, :string
    add_column :users, :region_code, :string
    add_column :users, :region_name, :string
    
    add_index :users, :lat
    add_index :users, :lng
  end
end
