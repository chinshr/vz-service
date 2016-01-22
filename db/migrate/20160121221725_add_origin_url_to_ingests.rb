class AddOriginUrlToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :origin_url, :text
  end
end
