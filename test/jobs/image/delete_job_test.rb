require 'test_helper'

class Image::DeleteJobTest < ActiveSupport::TestCase

  setup do
    @image = FactoryGirl.create(:image, :document_ingest)
  end

  should "remove image" do
    assert_difference "Image.with_deleted.count", -1 do
      Image::DeleteJob.new.perform(@image.id)
    end
  end

  should "remove image when destroyed" do
    @image.destroy
    assert_difference "Image.with_deleted.count", -1 do
      Image::DeleteJob.new.perform(@image.id)
    end
  end

end