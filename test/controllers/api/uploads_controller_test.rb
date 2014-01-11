require 'test_helper'

class Api::UploadsControllerTest < ActionController::TestCase
  context "POST /api/uploads" do
    should "create audio upload" do
      post :create, :upload => {type: "audio", file_type: "audio/x-m4a", file_name: "sample.m4a", file_size: 62676,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/sample.m4a"}, 
        format: :json
      assert_response :success
      assert_response_body response
    end

    should "NOT create audio upload without file type audio" do
      post :create, :upload => {type: "audio", file_type: "XXX", file_name: "xxx.xxx", file_size: 1,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/xxx.xxx"}, 
        format: :json
      assert_response :unprocessable_entity
    end

    should "NOT create audio upload without type" do
      post :create, :upload => {file_type: "XXX", file_name: "xxx.xxx", file_size: 1,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/xxx.xxx"}, 
        format: :json
      assert_response :unprocessable_entity
    end
  end
  
  context "GET /uploads/:id" do
    should "return upload" do
      upload = FactoryGirl.create(:upload_audio)
      get :show, :id => upload.id, format: :json
      assert_response :success
      assert_response_body response
    end
  end

  context "PUT /uploads/:id" do
    should "update upload" do
      upload = FactoryGirl.create(:upload_audio)
      put :update, {:id => upload.id, :upload => {:title => "Fun Fest!", :description => "Interview taken at fun fest."}, format: :json}
      assert_response :success
      assert_response_body response
      assert_equal "Fun Fest!", upload.reload.title
      assert_equal "Interview taken at fun fest.", upload.reload.description
    end
  end

  context "DELETE /uploads" do
    should "destroy upload" do
      upload = FactoryGirl.create(:upload_audio)
      delete :destroy, {id: upload.id, format: :json}
      assert_response :success
      assert_equal 0, Upload.count
    end
  end
  
  should "get signput" do
    get :signput, :format => :json
    assert_response :success
  end
  
  protected
  
  def assert_response_body(response)
    body = JSON.parse(response.body)
    assert body.has_key?("upload")
    assert_attributes body["upload"]
  end
  
  def assert_attributes(attributes)
    assert attributes.has_key?("file_name")
    assert attributes.has_key?("file_type")
    assert attributes.has_key?("file_size")
    assert attributes.has_key?("s3_url")
    assert attributes.has_key?("locale")
    assert attributes.has_key?("slug")
    assert attributes.has_key?("title")
    assert attributes.has_key?("description")
    assert attributes.has_key?("status")
    assert attributes.has_key?("type")
    assert attributes.has_key?("updated_at")
    assert attributes.has_key?("created_at")
  end
end
