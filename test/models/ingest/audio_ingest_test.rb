require 'test_helper'

class Ingest::AudioIngestTest < ActiveSupport::TestCase
  should "create" do
    assert_difference "Ingest::AudioIngest.count", 1 do
      assert_difference "Upload::AudioUpload.count", 1 do
        ingest = FactoryGirl.create(:ingest_audio)
        assert_match /ai-.*/, ingest.uid
      end
    end
  end
end
