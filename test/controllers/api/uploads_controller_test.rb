require 'test_helper'

class Api::UploadsControllerTest < ActionController::TestCase
  context "POST /api/uploads" do
    should "create audio upload" do
      post :create, :upload => {type: "audio", file_type: "audio/x-m4a", file_name: "sample.m4a", file_size: 62676,
        s3_url: "http://s3.amazonaws.com/qscribe-uploads/amQW1N-sample.m4a", locale: "en-GB", :privacy => "private"}, 
        format: :json
      assert_response :success
      assert_response_body response
      
      upload = Upload.last
      assert_equal "Upload::Audio", upload.type 
      assert_equal "audio/x-m4a", upload.file_type 
      assert_equal "sample.m4a", upload.file_name 
      assert_equal 62676, upload.file_size
      assert_equal "http://s3.amazonaws.com/qscribe-uploads/amQW1N-sample.m4a", upload.s3_url
      assert_equal "en-GB", upload.locale
      assert_equal [:private], upload.privacy
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
      put :update, {:id => upload.id, :upload => {:title => "La fiesta!", :description => "Entrevista en la fiesta.", locale: "es-AR"}, format: :json}
      assert_response :success
      assert_response_body response
      assert_equal "La fiesta!", upload.reload.title
      assert_equal "Entrevista en la fiesta.", upload.reload.description
      assert_equal "es-AR", upload.reload.locale
    end
  end

  context "DELETE /uploads" do
    should "destroy upload" do
      upload = FactoryGirl.create(:upload_audio)
      assert_difference 'Document.count', -1 do
        assert_difference 'Ingest.count', -1 do
          assert_difference 'Upload.count', -1 do
            delete :destroy, {id: upload.id, format: :json}
            assert_response :success
          end
        end
      end
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
    assert attributes.has_key?("progress")
    assert attributes.has_key?("updated_at")
    assert attributes.has_key?("created_at")
  end
end
