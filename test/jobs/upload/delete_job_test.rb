require 'test_helper'

class Upload::DeleteJobTest < ActiveSupport::TestCase

  should "delete upload" do
    upload = FactoryGirl.create(:upload_audio)
    assert_difference "Upload.count", -1 do
      Upload::DeleteJob.new.perform(upload.id)
    end
  end

end