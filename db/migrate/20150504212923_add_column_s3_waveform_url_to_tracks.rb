class AddColumnS3WaveformUrlToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :s3_waveform_json_url, :string
  end
end
