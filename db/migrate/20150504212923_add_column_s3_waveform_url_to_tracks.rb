class AddColumnS3WaveformUrlToTracks < ActiveRecord::Migration
  def change
    add_column :tracks, :s3_waveform_url, :string
  end
end
