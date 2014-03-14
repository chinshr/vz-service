require 'test_helper'

class Ingest::AudioWorkerTest < ActiveSupport::TestCase
  
  setup do
    @ingest = FactoryGirl.create(:ingest_audio)
    
    Ingest::AudioWorker.any_instance.stubs(:s3_copy_object).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:s3_download_object).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:s3_delete_object).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:s3_upload_object).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:s3_delete_object_if_exists).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:s3_copy_object_if_exists).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:ffmpeg_convert_to_mp3).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:ffmpeg_convert_to_wav_and_strip_audio_channel).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:sox_normalize_audio).returns(true)

    Ingest::AudioWorker.jobs.clear
  end

  should "process until finished and finalized" do
    @ingest.start!
    assert_equal :starting, @ingest.state
    assert_nil @ingest.stage
    Ingest::AudioWorker.jobs.size == 1

    worker = Ingest::AudioWorker.new
    stub_transcribe_file(worker, ["I like finished pickles"])
    worker.perform(@ingest.id)
    
    @ingest.reload and @ingest.ingestable.reload
    
    assert_equal :finished, @ingest.state
    assert_equal 100, @ingest.progress
    assert_equal "finalized", @ingest.stage
    assert_equal "I like finished pickles", @ingest.ingestable.content
  end

  should "don't process when stopped " do
    @ingest.start!
    assert_equal :starting, @ingest.state
    @ingest.create_track(:s3_url => "http://s3.amazonaws.com/234klj32", :s3_mp3_url => "http://s3.amazonaws.com/234klj32.128.mp3")
    @ingest.save if @ingest.changed?
    @ingest.update_attribute(:stage, "transcribe")
    @ingest.fail!  # oops! somthing bad happened...
    assert_equal :stopped, @ingest.state
    assert_equal 0, @ingest.iteration

    Ingest::AudioWorker.jobs.clear
    @ingest.start!  # let's continue processing...
    assert_equal :starting, @ingest.state
    assert_equal 1, Ingest::AudioWorker.jobs.size
    
    worker = Ingest::AudioWorker.new
    stub_transcribe_file(worker, ["I like sour pickles"])
    worker.perform(@ingest.id)
    
    @ingest.reload and @ingest.ingestable.reload
    assert_equal :finished, @ingest.state
    assert_equal 100, @ingest.progress
    assert_equal "finalized", @ingest.stage
    assert_equal "I like sour pickles", @ingest.ingestable.content
  end

  should "reset when resetting" do
    @ingest.update_attributes(:aasm_state => "resetting")
    assert_equal :resetting, @ingest.state

    worker = Ingest::AudioWorker.new
    worker.perform(@ingest.id)
    
    @ingest.reload
    assert_equal :reset, @ingest.state
    assert_equal 1, @ingest.iteration
  end

  protected
  
  def stub_transcribe_file(worker, segments)
    str = <<-END
      def transcribe_file(filename)
        segments = #{segments}
        segments.each_with_index do |segment, index|
          response = {"status" => 0, "id" => "", "hypotheses" => [segment, 0.79]}
          @ingest.ingestable.segments.create(
            :offset      => index,
            :duration    => 1,
            :start_time  => index,
            :end_time    => index + 1,
            :text        => segment,
            :score       => 0.79,
            :response    => response
          )
        end
        {"segments" => [{}]}
      end
    END
    worker.instance_eval str
  end
end
