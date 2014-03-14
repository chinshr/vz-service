class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.string :s3_url
      t.string :s3_mp3_url
      t.timestamps
    end
  end
end
