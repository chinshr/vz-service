require 'test_helper'

class Api::UploadsControllerTest < ActionController::TestCase
  context "#create" do
    should "post #create" do
      post :create, :upload => {type: "audio", file_type: "audio/x-m4a", file_name: "sample.m4a", file_size: 62676,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/sample.m4a"}, 
        format: :json
      assert_response :success
    end

    should "post #create and create ingest" do
      post :create, :upload => {type: "audio", file_type: "audio/x-m4a", file_name: "sample.m4a", file_size: 62676,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/sample.m4a"}, 
        format: :json
      assert_response :success
      json = JSON.parse(response.body).symbolize_keys
      assert json.has_key?(:upload)
      upload = json[:upload]
      assert upload.has_key?("status")
      assert upload.has_key?("title")
      assert upload.has_key?("description")
      assert upload.has_key?("slug")
    end

    should "not #create without file type audio" do
      post :create, :upload => {type: "audio", file_type: "XXX", file_name: "xxx.xxx", file_size: 1,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/xxx.xxx"}, 
        format: :json
      assert_response :unprocessable_entity
    end

    should "not #create with missing type" do
      post :create, :upload => {file_type: "XXX", file_name: "xxx.xxx", file_size: 1,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/xxx.xxx"}, 
        format: :json
      assert_response :unprocessable_entity
    end
  end
  
  should "get signput" do
    get :signput, :format => :json
    assert_response :success
  end
end
