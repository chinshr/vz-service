class AddS3UrlToIngests < ActiveRecord::Migration
  def change
    add_column :ingests, :s3_url, :string
  end
end
