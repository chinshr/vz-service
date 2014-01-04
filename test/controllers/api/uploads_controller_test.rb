require 'test_helper'

class Api::UploadsControllerTest < ActionController::TestCase
  should "post create" do
    post :create, file_type: "audio/x-m4a", file_name: "sample.m4a", file_size: 62676,
      s3_url: "http://s3.amazonaws.com/qscribe-uploads/default_name", 
      format: :json
      
    assert_response :success
  end
  
  should "get signput" do
    get :signput, :format => :json
    assert_response :success
  end
end
