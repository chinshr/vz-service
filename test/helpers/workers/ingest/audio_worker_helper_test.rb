require 'test_helper'


class AudioWorkerTest
  include Workers::Ingest::AudioWorkerHelper
  attr_reader :ingest

  class Chunk
    attr_accessor :id, :engine, :splitter

    class Splitter
      attr_accessor :chunks
      
      def initialize(chunk_count)
        self.chunks = chunk_count.times.inject([]) {|t, i| t << i + 1}
      end
    end
    
    
    def initialize(id, engine, chunk_count)
      self.id, self.engine = id, engine
      self.splitter = Splitter.new(chunk_count)
    end
  end
  
  def initialize(ingest_id = nil)
    @ingest = Ingest::Audio.find(ingest_id) if ingest_id
    document # need to reference the document, otherwise, for some reason it cannot be referenced. AR bug?
    
    Transcribe.class_eval do
      protected 

      def document
        @ingest.ingestable
      end

      def transcribe_file(audio)
        ActiveRecord::Base.connection_pool.with_connection do
          if audio.engine.is_a? Speech::Engines::GoogleSpeechEngine
            @mutex.synchronize do
              Document::Chunk::GoogleSpeech.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(1, audio.engine, 3))
            end
            
            @mutex.synchronize do
              Document::Chunk::GoogleSpeech.create(:position => 2, :offset => 10, :text => "that macaronies are", :score => 0.65, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(2, audio.engine, 3))
            end
            
            @mutex.synchronize do
              Document::Chunk::GoogleSpeech.create(:position => 3, :offset => 20, :text => "the best food in the world", :score => 0.85, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(3, audio.engine, 3))
            end
          elsif audio.engine.is_a? Speech::Engines::AttSpeechEngine
            @mutex.synchronize do
              Document::Chunk::AttSpeech.create(:position => 1, :offset => 0,  :text => "I have to pray", :score => 0.70, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(1, audio.engine, 3))
            end

            @mutex.synchronize do
              Document::Chunk::AttSpeech.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.70, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(2, audio.engine, 3))
            end

            @mutex.synchronize do
              Document::Chunk::AttSpeech.create(:position => 3, :offset => 20, :text => "the best mushrooms in the whirlwind.", :score => 0.70, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(3, audio.engine, 3))
            end
          elsif audio.engine.is_a? Speech::Engines::NuanceDragonEngine
            @mutex.synchronize do
              Document::Chunk::NuanceDragon.create(:position => 1, :offset => 0,  :text => "I have say", :score => 0, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(1, audio.engine, 3))
            end
            @mutex.synchronize do
              Document::Chunk::NuanceDragon.create(:position => 2, :offset => 0,  :text => "that some macaronies are", :score => 0, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(2, audio.engine, 3))
            end
            @mutex.synchronize do
              Document::Chunk::NuanceDragon.create(:position => 3, :offset => 0,  :text => "the cesty food in the world", :score => 0, :document => document)
              @queue.push(AudioWorkerTest::Chunk.new(3, audio.engine, 3))
            end
          end
        end
      end
    end
  end

  def document
    @ingest.ingestable
  end
  
  def transcribe!
    transcribe = Transcribe.new(@ingest, :chunk_size => @chunk_size, :chunk_timeout => 0.25)
    transcribe.perform("dummy.wav")
  end
end

class Workers::Ingest::AudioWorkerHelperTest < ActionView::TestCase
  setup do
    @ingest = FactoryGirl.create(:ingest_audio, :ingestable => FactoryGirl.create(:document))
    @worker = AudioWorkerTest.new(@ingest.id)
  end

  should "transcribe file" do
    threads = @worker.transcribe!

    @ingest.reload
    assert_equal 9, @ingest.ingestable.chunks.count
    assert_equal 3, @ingest.ingestable.chunks.any_of_type(:google_speech).count
    assert_equal 3, @ingest.ingestable.chunks.any_of_type(:att_speech).count
    assert_equal 3, @ingest.ingestable.chunks.any_of_type(:nuance_dragon).count
    assert_equal 100, @ingest.progress
  end

  should "normalize document chunks" do
    threads = @worker.transcribe!
    @worker.normalize_document_chunk_scores(@ingest.ingestable)
    
    assert_equal 3, @ingest.ingestable.chunks.best.count
    assert_equal "I hate to say that macaronies are the best food in the world", @ingest.ingestable.chunks.best.text
  end
  
end
