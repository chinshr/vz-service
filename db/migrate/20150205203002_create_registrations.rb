class CreateRegistrations < ActiveRecord::Migration
  def change
    create_table :registrations do |t|
      t.string   "email"
      t.string   "locale", :limit => 8
      t.string   "country_code", :limit => 2
      t.string   "ip_address"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "time_zone"
      t.decimal  "lat", :precision => 11, :scale => 8
      t.decimal  "lng", :precision => 11, :scale => 8
      t.string   "address"
      t.string   "city"
      t.string   "postal_code"
      t.string   "region_code"
      t.string   "type"
      t.string   "uid"
      t.string   "referrer_uid"
      t.boolean  "opt_in", :default => false, :null => false
      t.text     "fields"
      t.text     "user_data"
      t.string   "region_name"

      t.timestamps
    end

    add_index :registrations, :email, :unique => true
    add_index :registrations, :referrer_uid
    add_index :registrations, :type
    add_index :registrations, :uid
  end
end
