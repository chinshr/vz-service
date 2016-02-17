require 'test_helper'

class Ingest::DeleteJobTest < ActiveSupport::TestCase
  setup do
    @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "removing")
  end

  should "delete ingest" do
    assert_difference "Ingest.count", -1 do
      Ingest::DeleteJob.new.perform(@ingest.id)
    end
  end

  should "delete already destroyed ingest" do
    @ingest.destroy
    assert_difference "Ingest.with_deleted.count", -1 do
      Ingest::DeleteJob.new.perform(@ingest.id)
    end
  end

end
