require "rubygems"
require "aws-sdk"
require "speech"

class Ingest::RemoveWorker
  include Sidekiq::Worker
  include Workers::Ingest::AudioWorkerHelper
  
  sidekiq_options :queue => :default, :retry => false, :backtrace => true

  STAGES = {
    :initialize_pipeline                         => 0,
    :move_object_from_inbound_to_outbound_bucket => 10,
    :download_object_from_outbound_bucket        => 20,
    :normalize_original_audio_file               => 30,
    :noise_reduce_audio_file                     => 35, 
    :create_mp3_and_upload                       => 40,
    :transcribe                                  => 50,
    :finalized                                   => 60
  }
  
  def initialize(ingest_id = nil)
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )
    
    # For server debugging purposes
    @ingest = Ingest::Audio.find(ingest_id) if ingest_id
  end
  
  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest::Audio.find(ingest_id)

    if @ingest.state == :removing
      when_liberated do
        Rails.logger.info "--> processing #{@ingest.state}"
        remove_all_s3_objects
        @ingest.process!  # => :removed
        @ingest.destroy
      end
    end
  end
  
end