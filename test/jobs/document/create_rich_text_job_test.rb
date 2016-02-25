require 'test_helper'

class Document::CreateRichTextJobTest < ActiveSupport::TestCase

  setup do
    @ingest   = FactoryGirl.create(:media_ingest_as_audio)
    @document = @ingest.document

    @c1 = Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0,  :duration => 0.72, :text => "I hate to say", :score => 0.80, :document => @ingest.document, :ingest => @ingest)
    @c2 = Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "cat maths are", :score => 0.65, :document => @ingest.document, :ingest => @ingest)
    @c3 = Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the cesty food in the world", :score => 0.85, :document => @ingest.document, :ingest => @ingest)

    @c4 = Chunk::AttSpeechChunk.create(:position => 1, :offset => 0,  :duration => 0.72, :text => "I have to pray", :score => 0.72, :document => @ingest.document, :ingest => @ingest)
    @c5 = Chunk::AttSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "that macaronies are", :score => 0.78, :document => @ingest.document, :ingest => @ingest)
    @c6 = Chunk::AttSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the best mushrooms in the whirlwind.", :score => 0.70, :document => @ingest.document, :ingest => @ingest)

    @c7 = Chunk::NuanceDragonChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I have say", :score => 0.34, :document => @ingest.document, :ingest => @ingest)
    @c8 = Chunk::NuanceDragonChunk.create(:position => 2, :offset => 0, :duration => 0.89, :text => "that some macaronies are", :score => 0.63, :document => @ingest.document, :ingest => @ingest)
    @c9 = Chunk::NuanceDragonChunk.create(:position => 3, :offset => 0, :duration => 1.21, :text => "the best food in the world", :score => 0.87, :document => @ingest.document, :ingest => @ingest)
  end

  should "set rich text" do
    Document::CreateRichTextJob.new.perform(@document.id)
    assert_equal @document.best_chunks.rich_text, @document.reload.rich_text
  end

  should "not set rich text without segments" do
    document = FactoryGirl.create(:document_with_track)
    Document::CreateRichTextJob.new.perform(document.id)
    assert_equal({"ops"=>[]}, document.reload.rich_text)
  end

end