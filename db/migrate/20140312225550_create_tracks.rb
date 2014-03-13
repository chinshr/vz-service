class CreateTracks < ActiveRecord::Migration
  def change
    create_table :tracks do |t|
      t.string :s3_url
      t.string :mp3_s3_url
      t.timestamps
    end
  end
end
