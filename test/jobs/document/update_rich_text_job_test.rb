require 'test_helper'

class Document::UpdateRichTextJobTest < ActiveSupport::TestCase

  should "set/get content as rich_text with attributes" do
    document = FactoryGirl.create(:document)
    c1 = Chunk::GoogleSpeechChunk.create(position: 1, offset: 0, text: "Das ist", score: 0.80, document: document)
    t1 = c1.create_track(s3_url: "http://t1", duration: 1.5)

    assert_nil document[:rich_text]
    Document::CreateRichTextJob.new.perform(document.id)
    assert_not_nil document.rich_text
    c1.start_time = 0.32
    c1.end_time   = 1.41
    c1.score      = 0.2
    rt = {"ops"=>[{"insert"=>"Das ist das", "attributes"=>{"segment" => c1.segment_id}}]}
    Document::UpdateRichTextJob.new.perform(document.id, rt)
    document = Document.find(document.id)
    assert_equal 0.32, c1.reload.start_time.to_f
    assert_equal 1.41, c1.reload.end_time.to_f
    assert_equal 1.0, c1.reload.score.to_f
    assert_equal "Das ist das", c1.reload.text
  end

end