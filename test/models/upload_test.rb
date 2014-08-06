require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  context "associations" do
    should have_one :ingest
    should belong_to :session
    should belong_to :user
  end
  
  context "validations" do
    should validate_presence_of :file_name
    should ensure_length_of(:file_name).is_at_most(255)
    should validate_presence_of :file_type
    should ensure_length_of(:file_type).is_at_most(255)
    should validate_presence_of :s3_url
    should ensure_length_of(:s3_url).is_at_most(255)
  end

  context "scopes" do
    setup do
      @upload = FactoryGirl.create(:upload_audio)
    end
    
    should "have any_of_states" do
      @upload.ingest.update_attribute(:aasm_state, "started")
      assert_equal [@upload], Upload.any_of_states([:starting, :started])
    end

    should "have none_of_states" do
      @upload.ingest.update_attribute(:aasm_state, "started")
      assert_equal [@upload], Upload.none_of_states([:created, :starting, :stopping, :stopped, :resetting, :reset, :removing, :removed])
    end
  end
  
  should "humanize file name" do
    assert_equal "I like pickles", Upload.new(file_name: "i_like_pickles.m4a").humanized_file_name
    assert_equal "I like pickles", Upload.new(file_name: "i-like-pickles.m4a").humanized_file_name
  end
  
  should "have s3_key" do
    upload = FactoryGirl.create(:upload_audio, :s3_url => "http://s3.amazonaws.com/dropbox/61glI7mwmN")
    assert_equal "61glI7mwmN", upload.s3_key
  end
  
  should "generate object name" do
    assert_equal 10, Upload.generate_object_name.length
  end
end
