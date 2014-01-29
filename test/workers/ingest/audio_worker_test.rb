require 'test_helper'

class Ingest::AudioWorkerTest < ActiveSupport::TestCase
  
  setup do
    AWS.stub!

    @ingest = FactoryGirl.create(:ingest_audio)
    
    Ingest::AudioWorker.any_instance.stubs(:s3_copy_object).returns(true)
    Ingest::AudioWorker.any_instance.stubs(:s3_download_object).returns(true)
    
    Ingest::AudioWorker.any_instance.stubs(:s3_delete_object).returns(true)
  end
  
  should "process until finished and finalized" do
    @ingest.start!
    assert_equal :starting, @ingest.state

    stub_transcribe_file(@ingest, ["I like pickles"])
    
    Ingest::AudioWorker.new.perform(@ingest.id)
    @ingest.reload and @ingest.ingestable.reload
    
    assert_equal :finished, @ingest.state
    assert_equal 100, @ingest.progress
    assert_equal "finalized", @ingest.stage
    assert_equal "I like pickles", @ingest.ingestable.content
  end

  should "continue processing when stopped " do
    @ingest.start!
    assert_equal :starting, @ingest.state
    @ingest.update_attribute(:stage, "transcribe")
    @ingest.fail!
    assert_equal :stopped, @ingest.state
    assert_equal 0, @ingest.iteration

    stub_transcribe_file(@ingest, ["I like sour pickles"])
    
    Ingest::AudioWorker.new.perform(@ingest.id)
    @ingest.reload and @ingest.ingestable.reload
    
    assert_equal :finished, @ingest.state
    assert_equal 100, @ingest.progress
    assert_equal "finalized", @ingest.stage
    assert_equal "I like sour pickles", @ingest.ingestable.content
  end

  should "reset when resetting" do
    @ingest.start!
    assert_equal :starting, @ingest.state
    @ingest.process!
    assert_equal :started, @ingest.state
    @ingest.stop!
    assert_equal :stopping, @ingest.state
    @ingest.process!
    assert_equal :stopped, @ingest.state
    @ingest.reset!
    assert_equal :resetting, @ingest.state
    assert_equal 0, @ingest.iteration

    stub_transcribe_file(@ingest, [])
    
    Ingest::AudioWorker.new.perform(@ingest.id)
    @ingest.reload and @ingest.ingestable.reload
    
    assert_equal :reset, @ingest.state
    assert_equal 1, @ingest.iteration
  end

  protected
  
  def stub_transcribe_file(ingest, segments)
    create_segments_proc = Proc.new do |ingest_id, segments| 
      ingest = Ingest::Audio.find(ingest_id)
      segments.each_with_index do |segment, index|
        response = {"status" => 0, "id" => "#{(rand*1000).to_i}", "hypotheses" => [segment, 0.79]}
        ingest.segments.create(
          :offset      => index,
          :duration    => 1,
          :start_time  => index,
          :end_time    => index + 1,
          :best_text   => segment,
          :best_score  => 0.79,
          :response    => response
        )
      end
      {"segments" => [{}]}
    end
    Ingest::AudioWorker.any_instance.stubs(:transcribe_file).returns(create_segments_proc.call(ingest.id, segments))
  end
end
