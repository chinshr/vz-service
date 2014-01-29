require 'test_helper'

class Ingest::AudioTest < ActiveSupport::TestCase
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
  
  should "have segments and remove them when starting ingest" do
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
    assert ingest.messages.empty?
    assert_equal 0, ingest.segments.count
  end
end
