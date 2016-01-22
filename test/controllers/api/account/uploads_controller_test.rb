require 'test_helper'

class Api::Account::UploadsControllerTest < ActionController::TestCase
  setup do
    @user = FactoryGirl.create :user
    sign_in :user, @user
  end

  context "POST /api/account/uploads" do
    should "create s3 audio upload when signed in" do
      assert_difference 'Document.count', 1 do
        assert_difference 'Ingest::MediaIngest.count', 1 do
          assert_difference 'Upload::MediaUpload.count', 1 do
            post :create, :upload => {
              :file_name => "i-like-pickles.wav",
              :source_url => "http://s3.amazonaws.com/vz-test-dropbox/8enYwMjB0B",
              :file_type => "audio/wav",
              :file_size => 225284,
              :type => "audio",
              :locale => "en-UK",
              :privacy => "private",
              :metadata => {"te_name" => "pocketsphinx"}
            }, format: :json
            assert_response :success
            assert_response_body_attributes_with "upload"

            upload = Upload.last
            assert_equal @user.id, upload.user.id
            assert_equal "Upload::MediaUpload", upload.type
            assert_equal "audio/wav", upload.file_type
            assert_equal "i-like-pickles.wav", upload.file_name
            assert_equal 225284, upload.file_size
            assert_equal "http://s3.amazonaws.com/vz-test-dropbox/8enYwMjB0B", upload.source_url
            assert_equal "en-UK", upload.locale
            assert_equal ["private"], upload.privacy
            assert_equal({"te_name"=>"pocketsphinx"}, upload.metadata)
            assert_equal 0, upload.progress
            assert_equal :starting, upload.state
          end
        end
      end
    end

    should "create s3 video upload when signed in" do
      assert_difference 'Document.count', 1 do
        assert_difference 'Ingest::MediaIngest.count', 1 do
          assert_difference 'Upload::MediaUpload.count', 1 do
            post :create, :upload => {
              :file_name => "i-like-videos.mp4",
              :source_url => "http://s3.amazonaws.com/vz-test-dropbox/6e3YeXJ3Ad",
              :file_type => "video/mp4",
              :file_size => 53232284,
              :locale => "de-DE",
              :privacy => "unlisted"
            }, format: :json
            assert_response :success
            assert_response_body_attributes_with "upload"

            upload = Upload.last
            assert_equal @user.id, upload.user.id
            assert_equal "Upload::MediaUpload", upload.type
            assert_equal "video/mp4", upload.file_type
            assert_equal "i-like-videos.mp4", upload.file_name
            assert_equal 53232284, upload.file_size
            assert_equal "http://s3.amazonaws.com/vz-test-dropbox/6e3YeXJ3Ad", upload.source_url
            assert_equal "de-DE", upload.locale
            assert_equal ["unlisted"], upload.privacy
            assert_equal 0, upload.progress
            assert_equal :starting, upload.state
          end
        end
      end
    end

    should "create mp3 source media when signed in" do
      assert_difference 'Document.count', 1 do
        assert_difference 'Ingest::MediaIngest.count', 1 do
          assert_difference 'Upload::MediaUpload.count', 1 do
            stub_request(:get, "https://www.voyz.es/samples/genesis-1-1-en-us.m4a").
              with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:10.0) Gecko/20100101 Firefox/10.0'}).
              to_return(:status => 200, :body => "", :headers => {'Content-Type' => 'audio/mpeg'})

            post :create, :upload => {
              :source_url => "https://www.voyz.es/samples/genesis-1-1-en-us.m4a",
              :use_source_annotations => "",
              :locale => "en-US"
            }, format: :json
            assert_response :success
            assert_response_body_attributes_with "upload"

            upload = Upload.last
            assert_equal "https://www.voyz.es/samples/genesis-1-1-en-us.m4a", upload.source_url
            assert_equal @user.id, upload.user.id
            assert_equal "Upload::MediaUpload", upload.type
            assert_equal "audio/mpeg", upload.file_type
            assert_equal "Genesis 1 1 En Us", upload.title
            assert_equal false, upload.use_source_annotations
            assert_equal :starting, upload.state
          end
        end
      end
    end

    should "create from YouTube source media when signed in" do
      assert_difference 'Document.count', 1 do
        assert_difference 'Ingest::MediaIngest.count', 1 do
          assert_difference 'Upload::MediaUpload.count', 1 do
            stub_request(:get, "https://www.youtube.com/watch?v=aORId5oBmCM").
              with(:headers => {'Accept'=>'*/*'}).
              to_return(:status => 200, :body => '<html><head><title>Foo title</title><meta name="description" content="Bar description"><meta name="keywords" content="foo, bar"></head></html>', :headers => {})

            post :create, :upload => {
              :source_url => "https://www.youtube.com/watch?v=aORId5oBmCM",
              :use_source_annotations => "1",
              :locale => "en-US"
            }, format: :json
            assert_response :success
            assert_response_body_attributes_with "upload"

            upload = Upload.last
            assert_equal "https://www.youtube.com/watch?v=aORId5oBmCM", upload.source_url
            assert_equal @user.id, upload.user.id
            assert_equal "Upload::MediaUpload", upload.type
            assert_equal "Foo Title", upload.title
            assert_equal "Bar description", upload.description
            assert_equal true, upload.use_source_annotations
            assert_equal ["foo", "bar"], upload.tag_list
            assert_equal :starting, upload.state
          end
        end
      end
    end

    should "NOT create media upload when signed out" do
      sign_out :user
      post :create, :upload => {:file_name => "i-like-pickles.wav", :source_url => "http://s3.amazonaws.com/vz-test-dropbox/8enYwMjB0B",
        :file_type => "audio/wav", :file_size => 225284, :type => "audio", :locale => "en-UK", :privacy => "private"},
        format: :json
      assert_response :unauthorized
    end

    should "NOT create media upload without file_type audio" do
      post :create, :upload => {type: "audio", file_type: "XXX", file_name: "xxx.xxx", file_size: 1,
        source_url: "http://s3.amazonaws.com/vz-test-dropbox/xxx.xxx"},
        format: :json
      assert_response :unprocessable_entity
    end

    should "NOT create media upload without type" do
      post :create, :upload => {file_type: "XXX", file_name: "xxx.xxx", file_size: 1,
        source_url: "http://s3.amazonaws.com/vz-test-dropbox/xxx.xxx"},
        format: :json
      assert_response :unprocessable_entity
    end
  end

  context "GET /api/account/uploads" do
    setup do
      @upload1      = FactoryGirl.create(:media_upload_as_audio)
      @upload1.user = @user and @upload1.save
      @upload2      = FactoryGirl.create(:media_upload_as_audio)
      @upload2.user = @user and @upload2.save
    end

    should "get all user's uploads" do
      FactoryGirl.create(:media_upload_as_audio)  # another user's upload
      get :index, format: :json
      assert_response :success
      assert response_body.has_key?("uploads"), "should have root"
      assert_equal 2, response_body["uploads"].size, "should only return user's uploads"
      assert_attributes response_body["uploads"].first
    end

    should "NOT return uploads when signed out" do
      sign_out :user
      get :index, format: :json
      assert_response :unauthorized
    end

    context "filters" do
      should "#any_of_status" do
        @upload2.ingest.update_attribute(:aasm_state, "stopped")
        get :index, :any_of_status => [Ingest::STATES[:stopped]], format: :json
        assert_response :success
        assert response_body.has_key?("uploads"), "should have root"
        assert_equal 1, response_body["uploads"].size
        assert_attributes response_body["uploads"].first
        assert_equal Ingest::STATES[:stopped], response_body["uploads"].first["status"], "should be 'stopped' = #{Ingest::STATES[:stopped]}"
      end

      should "#none_of_status" do
        @upload2.ingest.update_attribute(:aasm_state, "stopped")
        get :index, :none_of_status => [Ingest::STATES[:stopped]], format: :json
        assert_response :success
        assert response_body.has_key?("uploads"), "should have root"
        assert_equal 1, response_body["uploads"].size
        assert_attributes response_body["uploads"].first
        assert_not_equal Ingest::STATES[:stopped], response_body["uploads"].first["status"], "should not be 'stopped' = #{Ingest::STATES[:stopped]}"
      end

      should "#limit" do
        get :index, :limit => 1, format: :json
        assert_response :success
        assert response_body.has_key?("uploads"), "should have root"
        assert_equal 1, response_body["uploads"].size
      end

      context "sort_order" do
        should "sort all ASC by values #id, #created_at" do
          get :index, :sort_order => ["id", "created_at"], format: :json
          assert_response :success
          assert response_body.has_key?("uploads"), "should have root"
          assert_equal 2, response_body["uploads"].size
        end

        # query "sort_order[created_at]=desc&sort_order[id]=asc"
        # Note: CGI.unescape({:a => "a", :b => ["c", "d", "e"]}.to_query)
        should "sort values and order #id ASC, #created_at DESC" do
          get :index, :sort_order => [{"id" => "asc", "created_at" => "desc"}], format: :json
          assert_response :success
          assert response_body.has_key?("uploads"), "should have root"
          assert_equal 2, response_body["uploads"].size
        end
      end
    end
  end

  context "GET /api/account/uploads/count.json" do
    setup do
      @upload1      = FactoryGirl.create(:media_upload_as_audio)
      @upload1.user = @user and @upload1.save
      @upload2      = FactoryGirl.create(:media_upload_as_audio)
      @upload2.user = @user and @upload2.save
    end

    should "get count" do
      get :count, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal 2, response_body["count"], "should have count uploads"
    end
  end

  context "GET /api/account/uploads/:id" do
    should "get upload with :id" do
      upload = FactoryGirl.create(:media_upload_as_audio)
      upload.user = @user and upload.save
      get :show, :id => upload.id, format: :json
      assert_response :success
      assert_response_body_attributes_with "upload"
    end

    should "get 404 not found error with invalid :id" do
      other_upload = FactoryGirl.create(:media_upload_as_audio)
      get :show, :id => other_upload.id, format: :json
      assert_response :missing
      assert_equal true, response_body.has_key?("code")
      assert_equal Api::Code::RECORD_NOT_FOUND, response_body["code"]
      assert_equal true, response_body.has_key?("errors")
    end

    should "get 401 unauthorized error when when signed out" do
      sign_out :user
      get :show, :id => 1, format: :json
      assert_response :unauthorized
    end
  end

  context "PUT /api/account/uploads/:id" do
    should "update upload" do
      upload = FactoryGirl.create(:media_upload_as_audio)
      upload.user = @user and upload.save
      put :update, {:id => upload.id, :upload => {:title => "La fiesta!", :description => "Entrevista en la fiesta.",
        :tag_list => ["entrevista", "fiesta"], locale: "es-AR", :privacy => "private"}, format: :json}
      assert_response :success
      assert_response_body_attributes_with "upload"
      assert_equal "La fiesta!", upload.reload.title
      assert_equal "Entrevista en la fiesta.", upload.reload.description
      assert_equal ["entrevista", "fiesta"], upload.reload.tag_list
      assert_equal ["entrevista", "fiesta"], upload.user.owned_tags.map(&:name).sort
      assert_equal "es-AR", upload.reload.locale
      assert_equal ["private"], upload.reload.privacy
    end

    should "NOT update upload when signed out" do
      sign_out :user
      put :update, {:id => 1, :upload => {:title => "La fiesta!", :description => "Entrevista en la fiesta.", locale: "es-AR"}, format: :json}
      assert_response :unauthorized
    end

    should "invoke remove event" do
      upload = FactoryGirl.create(:media_upload_as_audio)
      upload.user = @user and upload.save
      put :update, {:id => upload.id, :upload => {:event => "remove"}, format: :json}
      assert_response :success
      assert_response_body_attributes_with "upload"
      assert_equal 7, response_body["upload"]["status"]
      assert_equal true, response_body["upload"]["events"].include?('remove')
      assert_equal true, response_body["upload"]["events"].include?('process')
      assert_equal true, response_body["upload"]["events"].include?('fail')
    end
  end

  context "DELETE /api/account/uploads/:id" do
    should "destroy upload" do
      upload = FactoryGirl.create(:media_upload_as_audio)
      upload.user = @user and upload.save
      assert_no_difference 'Document.count' do
        assert_no_difference 'Ingest.count', -1 do
          assert_enqueued_with(job: Upload::DeleteJob) do
          #assert_difference 'Upload.count', -1 do
            delete :destroy, {id: upload.id, format: :json}
            assert_response :success
            assert_equal :removing, upload.ingest.reload.state
            assert_response_body_attributes_with "upload"
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

  context "GET /api/account/upload/sign_s3" do
    should "get sign_s3" do
      get :sign_s3, :format => :json
      assert_response :success
    end

    should "NOT get sign_s3 when signed out" do
      sign_out :user
      get :sign_s3, :format => :json
      assert_response :unauthorized
    end
  end

  protected

  def assert_attributes(response, expected_attributes = {})
    %w(id uid file_name file_type file_size source_url locale slug slug_id title description tag_list privacy status type progress events updated_at created_at use_source_annotations metadata).each do |key|
      assert response.has_key?(key), "should containt key '#{key}' in response '#{response}'"
    end
  end
end
