require 'test_helper'

class Image::ImageFormatTest < ActiveSupport::TestCase

  should "#create" do
    assert_difference "Image::ImageFormat.count" do
      FactoryGirl.create(:image_format)
    end
  end

end
