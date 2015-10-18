require 'test_helper'

class Ingest::VideoIngestTest < ActiveSupport::TestCase
  should "create" do
    assert_difference "Ingest::VideoIngest.count", 1 do
      assert_difference "Upload::VideoUpload.count", 1 do
        ingest = FactoryGirl.create(:ingest_video)
      end
    end
  end
end