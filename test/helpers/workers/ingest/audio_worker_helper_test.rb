require 'test_helper'

class AudioWorkerTest
  include Workers::Ingest::AudioWorkerHelper
  attr_reader :ingest
  
  def initialize(ingest_id = nil)
    @ingest = Ingest::Audio.find(ingest_id) if ingest_id
  end
  
  def document; @ingest.ingestable if @ingest; end
  
  def google_speech_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      Document::Segment::GoogleSpeech.create(:offset => 0, :document => FactoryGirl.create(:document))
    end
  end
  
  def att_speech_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      Document::Segment::AttSpeech.create(:offset => 0, :document => FactoryGirl.create(:document))
    end
  end
  
  def nuance_dragon_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      Document::Segment::NuanceDragon.create(:offset => 0, :document => FactoryGirl.create(:document))
    end
  end
end

class Workers::Ingest::AudioWorkerHelperTest < ActionView::TestCase

  should "transcribe file" do
    Document::Segment.destroy_all
    @ingest = FactoryGirl.create(:ingest_audio)
    worker  = AudioWorkerTest.new(@ingest.id)
    threads = worker.transcribe_file("dummy.wav")
    assert_equal 3, Document::Segment.count
    assert_equal 1, Document::Segment::GoogleSpeech.count
    assert_equal 1, Document::Segment::AttSpeech.count
    assert_equal 1, Document::Segment::NuanceDragon.count
  end
  
end
