require 'test_helper'

class Ingest::AudioTest < ActiveSupport::TestCase
  setup do
    Ingest::AudioWorker.jobs.clear
    ActionMailer::Base.deliveries.clear
  end
  
  context "associations" do
    should have_many :segments
  end

  should "delegate to document getters" do
    document = FactoryGirl.create(:document)
    ingest = FactoryGirl.create(:ingest_audio, :ingestable => document)
    assert_equal document.title, ingest.title
    assert_equal document.description, ingest.description
  end

  should "delegate to document setters" do
    document = FactoryGirl.create(:document)
    ingest = FactoryGirl.create(:ingest_audio, :ingestable => document)
    ingest.title = "Wizard of Oz!"
    ingest.description = "The wonderful Wizard of Oz!"
    assert_equal document.title, ingest.title
    assert_equal document.description, ingest.description
  end
  
  should "have segments and remove messages when reset" do
    document = FactoryGirl.create(:document)
    ingest   = FactoryGirl.create(:ingest_audio, :ingestable => document)
    segment1 = FactoryGirl.create(:ingest_audio_segment, :offset => 0, :ingest => ingest, :best_score => 0)
    segment2 = FactoryGirl.create(:ingest_audio_segment, :offset => 1, :ingest => ingest, :best_score => 0.5)
    segment3 = FactoryGirl.create(:ingest_audio_segment, :offset => 2, :ingest => ingest, :best_score => 1)
    assert_equal 3, ingest.segments.count
    assert_equal 0.5, ingest.score.to_f
    assert_equal 10.53, ingest.duration.to_f
    ingest.log! :error, "error message"
    assert_equal %({"error"=>["error message"]}), ingest.messages.to_s
    ingest.start!
    assert_equal :starting, ingest.state
    ingest.process!
    assert_equal :started, ingest.state
    ingest.stop!
    assert_equal :stopping, ingest.state
    ingest.process!
    assert_equal :stopped, ingest.state
    ingest.reset!
    assert_equal :resetting, ingest.state
    assert_equal false, ingest.messages.empty?
    ingest.process!
    assert_equal :reset, ingest.state
    assert_equal true, ingest.messages.empty?
  end
  
  should "create worker process with state machine" do
    ingest = FactoryGirl.create(:ingest_audio)
    Ingest::AudioWorker.jobs.clear
    
    ingest.start!  # inside model!
    assert_equal :starting, ingest.state
    assert_equal 1, Ingest::AudioWorker.jobs.size
    
    ingest.process!  # inside worker!
    assert_equal :started, ingest.state
    Ingest::AudioWorker.jobs.clear

    ingest.stop!  # inside model!
    assert_equal :stopping, ingest.state
    assert_equal 1, Ingest::AudioWorker.jobs.size
    
    ingest.process!  # inside worker!
    assert_equal :stopped, ingest.state
    Ingest::AudioWorker.jobs.clear
    
    ingest.reset!  # inside model!
    assert_equal :resetting, ingest.state
    assert_equal 1, Ingest::AudioWorker.jobs.size
    assert_equal 0, ingest.iteration
    
    ingest.process!  # inside worker!
    assert_equal :reset, ingest.state
    Ingest::AudioWorker.jobs.clear
    assert_equal 1, ingest.iteration
  end
  
  should "finish process with user" do
    ingest = FactoryGirl.create(:ingest_audio, :user => FactoryGirl.create(:user))
    
    ingest.start!  # inside model!
    assert_equal :starting, ingest.state
    
    ingest.process!  # inside worker!
    assert_equal :started, ingest.state

    ingest.finish!  # inside worker!
    assert_equal :finished, ingest.state
    
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal "Finished, '#{ingest.upload.file_name}' has been transcribed.", ActionMailer::Base.deliveries[0].subject
  end
  
end
