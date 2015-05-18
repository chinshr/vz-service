require "rubygems"
require "aws-sdk-v1"
require "speech"

class Ingest::RemoveWorker
  include Sidekiq::Worker
  include Workers::Ingest::AudioWorkerHelper

  sidekiq_options :queue => :default, :retry => false, :backtrace => true

  def initialize(ingest_id = nil)
    AWS.config(
      :access_key_id     => APP_CONFIG['S3_KEY'],    # '*** Provide access key ***'
      :secret_access_key => APP_CONFIG['S3_SECRET']  # '*** Provide secret key ***'
    )

    # For server debugging purposes
    @ingest = Ingest::AudioIngest.find(ingest_id) if ingest_id
  end

  def perform(ingest_id, options = {})
    options.symbolize_keys!
    @ingest = Ingest::AudioIngest.find(ingest_id)
    # puts "-------------> #{@ingest.inspect}"

    when_liberated do
      #Rails.logger.info "--> processing #{@ingest.state}"
      #puts "-------------> processing #{@ingest.state}"
      remove_all_s3_objects
      @ingest.delete
    end
  end

end