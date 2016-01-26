require 'test_helper'

class Image::RemoveJobTest < ActiveSupport::TestCase

  should "remove image" do
    image = FactoryGirl.create(:image, :document_ingest)
    assert_difference "Image.count", -1 do
      Image::RemoveJob.new.perform(image.id)
    end
  end

end