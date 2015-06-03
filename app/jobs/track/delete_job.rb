class Track::DeleteJob < ActiveJob::Base
  include Job::Helper
  queue_as :default

  def perform(track_id)
    if @track = Track.find_by_id(track_id)

      [:s3_key, :s3_mp3_key, :s3_waveform_json_key].each do |key_method|
        bucket_name = @track.send(:s3_origin_bucket_name)
        key         = @track.send(key_method)
        s3_delete_object_if_exists(bucket_name, key) if bucket_name && key
      end

      @track.delete
    end
  end
end
