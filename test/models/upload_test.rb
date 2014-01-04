require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  context "associations" do
    should have_one :ingest
  end
  
  context "validations" do
    should validate_presence_of :file_name
    should ensure_length_of(:file_name).is_at_most(255)
    should validate_presence_of :file_type
    should ensure_length_of(:file_type).is_at_most(255)
    should validate_presence_of :s3_url
    should ensure_length_of(:s3_url).is_at_most(255)
  end
  
  should "create" do
    upload = FactoryGirl.create(:upload)
    assert upload.valid?, "should be true"
  end
end
