require 'test_helper'

class AudioWorkerTest
  include Workers::Ingest::AudioWorkerHelper
  attr_reader :ingest
  
  def initialize(ingest_id = nil)
    @ingest = Ingest::Audio.find(ingest_id) if ingest_id
    document # need to reference the document, otherwise, for some reason it cannot be references. AR bug?
  end
  
  def document; ingest.ingestable; end
  
  def google_speech_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      Document::Chunk::GoogleSpeech.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :document => document)
      Document::Chunk::GoogleSpeech.create(:position => 2, :offset => 10, :text => "that macaronies are", :score => 0.65, :document => document)
      Document::Chunk::GoogleSpeech.create(:position => 3, :offset => 20, :text => "the best food in the world", :score => 0.85, :document => document)
    end
  end
  
  def att_speech_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      Document::Chunk::AttSpeech.create(:position => 1, :offset => 0,  :text => "I have to pray", :score => 0.70, :document => document)
      Document::Chunk::AttSpeech.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.70, :document => document)
      Document::Chunk::AttSpeech.create(:position => 3, :offset => 20, :text => "the best mushrooms in the whirlwind.", :score => 0.70, :document => document)
    end
  end
  
  def nuance_dragon_transcribe_file(filename)
    ActiveRecord::Base.connection_pool.with_connection do
      Document::Chunk::NuanceDragon.create(:position => 1, :offset => 0,  :text => "I have say", :score => 0, :document => document)
      Document::Chunk::NuanceDragon.create(:position => 2, :offset => 0,  :text => "that some macaronies are", :score => 0, :document => document)
      Document::Chunk::NuanceDragon.create(:position => 3, :offset => 0,  :text => "the cesty food in the world", :score => 0, :document => document)
    end
  end
end

class Workers::Ingest::AudioWorkerHelperTest < ActionView::TestCase
  setup do
    Document::Chunk.destroy_all
    @ingest = FactoryGirl.create(:ingest_audio, :ingestable => FactoryGirl.create(:document))
    @worker = AudioWorkerTest.new(@ingest.id)
  end

  should "transcribe file" do
    threads = @worker.transcribe_file("dummy.wav")

    assert_equal 9, @ingest.ingestable.chunks.count
    assert_equal 3, @ingest.ingestable.chunks.any_of_type(:google_speech).count
    assert_equal 3, @ingest.ingestable.chunks.any_of_type(:att_speech).count
    assert_equal 3, @ingest.ingestable.chunks.any_of_type(:nuance_dragon).count
  end

  should "normalize document chunks" do
    threads = @worker.transcribe_file("dummy.wav")
    @worker.normalize_document_chunk_scores(@ingest.ingestable)
    
    assert_equal 3, @ingest.ingestable.chunks.best.count
    assert_equal "I hate to say that macaronies are the best food in the world", @ingest.ingestable.chunks.best.text
  end
  
end
