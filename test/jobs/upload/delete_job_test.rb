require 'test_helper'

class Upload::DeleteJobTest < ActiveSupport::TestCase

  setup do
    @upload = FactoryGirl.create(:media_upload_as_audio)
  end

  should "delete resources" do
    assert_difference "Upload.count", -1 do
      Upload::DeleteJob.new.perform(@upload.id)
    end
  end

  should "delete destroyed upload" do
    @upload.destroy
    assert_difference "Upload.with_deleted.count", -1 do
      Upload::DeleteJob.new.perform(@upload.id)
    end
  end

end