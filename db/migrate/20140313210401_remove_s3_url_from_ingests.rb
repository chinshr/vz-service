class RemoveS3UrlFromIngests < ActiveRecord::Migration
  def up
    remove_column :ingests, :s3_url
  end
  
  def down
    add_column :ingests, :s3_url, :string
  end
end
