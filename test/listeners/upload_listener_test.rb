require 'test_helper'

class UploadListenerTest < ActiveSupport::TestCase

  should "#refresh_upload with media upload" do
    upload = FactoryGirl.create(:media_upload_as_audio)
    UploadListener.new.refresh_upload(upload)
  end

  should "#refresh_upload with image upload" do
    upload = FactoryGirl.create(:image_upload, :ingestable)
    UploadListener.new.refresh_upload(upload)
  end

end
