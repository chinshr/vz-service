require 'test_helper'

class Ingest::DeleteJobTest < ActiveSupport::TestCase

  should "delete ingest" do
    ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "removing")
    assert_difference "Ingest.count", -1 do
      assert_enqueued_with(job: Upload::DeleteJob) do
        Ingest::DeleteJob.new.perform(ingest.id)
      end
    end
  end

end
