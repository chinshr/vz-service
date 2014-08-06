require 'test_helper'

class Api::Account::UploadsControllerTest < ActionController::TestCase
  setup do
    @user = FactoryGirl.create :user
    sign_in :user, @user
  end
  
  context "POST /api/account/uploads" do
    should "create audio upload when signed in" do
      assert_difference 'Document.count', 1 do
        assert_difference 'Ingest::Audio.count', 1 do
          assert_difference 'Upload::Audio.count', 1 do
            post :create, :upload => {:file_name => "i-like-pickles.wav", :s3_url => "http://s3.amazonaws.com/qscribe-uploads/8enYwMjB0B", 
              :file_type => "audio/wav", :file_size => 225284, :type => "audio", :locale => "en-UK", :privacy => "private"}, 
              format: :json
            assert_response :success
            assert_response_body_with_upload_and_attributes
    
            upload = Upload.last
            assert_equal @user.id, upload.user.id
            assert_equal "Upload::Audio", upload.type 
            assert_equal "audio/wav", upload.file_type 
            assert_equal "i-like-pickles.wav", upload.file_name 
            assert_equal 225284, upload.file_size
            assert_equal "http://s3.amazonaws.com/qscribe-uploads/8enYwMjB0B", upload.s3_url
            assert_equal "en-UK", upload.locale
            assert_equal [:private], upload.privacy
            assert_equal 0, upload.progress
          end
        end
      end
    end
    
    should "NOT create audio upload when signed out" do
      sign_out :user
      post :create, :upload => {:file_name => "i-like-pickles.wav", :s3_url => "http://s3.amazonaws.com/qscribe-uploads/8enYwMjB0B", 
        :file_type => "audio/wav", :file_size => 225284, :type => "audio", :locale => "en-UK", :privacy => "private"}, 
        format: :json
      assert_response :unauthorized
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

  context "GET /api/account/uploads" do
    should "return uploads" do
      upload = FactoryGirl.create(:upload_audio)
      get :index, format: :json
      assert_response :success
    end
    
    should "NOT return uploads when signed out" do
      sign_out :user
      get :index, format: :json
      assert_response :unauthorized
    end
    
  end
  
  context "GET /api/account/uploads/:id" do
    should "return upload when signed in" do
      upload = FactoryGirl.create(:upload_audio)
      get :show, :id => upload.id, format: :json
      assert_response :success
      assert_response_body_with_upload_and_attributes
    end

    should "NOT return upload when signed out" do
      sign_out :user
      get :show, :id => 1, format: :json
      assert_response :unauthorized
    end
  end

  context "PUT /api/account/uploads/:id" do
    should "update upload" do
      upload = FactoryGirl.create(:upload_audio)
      put :update, {:id => upload.id, :upload => {:title => "La fiesta!", :description => "Entrevista en la fiesta.", locale: "es-AR"}, format: :json}
      assert_response :success
      assert_response_body_with_upload_and_attributes
      assert_equal "La fiesta!", upload.reload.title
      assert_equal "Entrevista en la fiesta.", upload.reload.description
      assert_equal "es-AR", upload.reload.locale
    end
    
    should "NOT update upload when signed out" do
      sign_out :user
      put :update, {:id => 1, :upload => {:title => "La fiesta!", :description => "Entrevista en la fiesta.", locale: "es-AR"}, format: :json}
      assert_response :unauthorized
    end
    
  end

  context "DELETE /api/account/uploads" do
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
    
    should "NOT destroy upload when signed out" do
      sign_out :user
      delete :destroy, {id: 1, format: :json}
      assert_response :unauthorized
    end
    
  end

  context "GET /api/account/upload/signput" do
    should "get signput" do
      get :signput, :format => :json
      assert_response :success
    end

    should "NOT get signput when signed out" do
      sign_out :user
      get :signput, :format => :json
      assert_response :unauthorized
    end
  end
  
  protected

  def json_response_body
    JSON.parse(response.body)
  end

  def assert_response_body_with_upload_and_attributes
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
