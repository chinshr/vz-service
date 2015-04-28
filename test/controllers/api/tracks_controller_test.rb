require 'test_helper'

class Api::TracksControllerTest < ActionController::TestCase
  setup do
    @user1    = FactoryGirl.create(:user)
    @user2    = FactoryGirl.create(:backend_user)

    @ingest   = FactoryGirl.create(:ingest_audio)
    @document = @ingest.document

    @t0 = @ingest.document.create_track(s3_url: "http://t0")
    @c1 = Chunk::GoogleSpeech.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :ingest => @ingest)
    @t1 = @c1.create_track(s3_url: "http://t1")
    @c2 = Chunk::GoogleSpeech.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.65, :ingest => @ingest)
    @t2 = @c2.create_track(s3_url: "http://t2")
    @c3 = Chunk::GoogleSpeech.create(:position => 3, :offset => 20, :text => "the cesty food in the world", :score => 0.85, :ingest => @ingest)
    @t3 = @c3.create_track(s3_url: "http://t3")

    sign_out :user
  end

  context "POST /api/documents/:document_id/tracks.json" do
    should "#create document master track" do
      sign_in :user, @user2
      post :create, document_id: @document.id, track: {s3_url: "http://t4"}, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal "http://t4", response_body["track"]["s3_url"]
    end

    should "#create chunk track" do
      sign_in :user, @user2
      post :create, document_id: @c1.id, track: {s3_url: "http://chunk-track1"}, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal "http://chunk-track1", response_body["track"]["s3_url"]
    end

    should "be unauthorized without user" do
      post :create, document_id: @document.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      post :create, document_id: @document.id, format: :json
      assert_response :unauthorized
    end
  end

  context "PUT /api/documents/:document_id/tracks/:id.json" do
    should "#update document master track" do
      sign_in :user, @user2
      put :update, document_id: @document.id, id: @t0.id, track: {s3_url: "http://update_t0"}, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal "http://update_t0", response_body["track"]["s3_url"]
    end

    should "#update chunk track" do
      sign_in :user, @user2
      put :update, document_id: @c1.id, id: @t1.id, track: {s3_url: "http://update-chunk-track1"}, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal "http://update-chunk-track1", response_body["track"]["s3_url"]
    end

    should "be unauthorized without user" do
      put :update, document_id: @document.id, id: @t0.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      put :update, document_id: @document.id, id: @t0.id, format: :json
      assert_response :unauthorized
    end
  end

  context "GET /api/documents/:document_id/tracks.json" do
    should "get index" do
      sign_in :user, @user2
      get :index, :document_id => @document.id, format: :json
      assert_response :success
      assert_equal 4, response_body["tracks"].size
      assert_attributes response_body["tracks"].first
      assert_equal "http://t0", response_body["tracks"].first["s3_url"]
    end

    should "be unauthorized without user" do
      get :index, :document_id => @document.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :index, :document_id => @document.id, format: :json
      assert_response :unauthorized
    end
  end

  context "GET /api/documents/:document_id/tracks/:id.json" do
    should "get show" do
      sign_in :user, @user2
      get :show, :document_id => @document.id, :id => @t0.id, format: :json
      assert_response :success
      assert_response_body_attributes_with "track"
    end

    should "be unauthorized without user" do
      get :show, :document_id => @document.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :show, :document_id => @document.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end
  end

  context "DELETE /api/documents/:document_id/tracks/:id.json" do
    should "#delete" do
      sign_in :user, @user2
      assert_difference "Track.count", -1 do
        delete :destroy, :document_id => @document.id, :id => @t0.id, format: :json
        assert_response :success
        assert_response_body_attributes_with "track"
      end
    end

    should "be unauthorized without user" do
      delete :destroy, :document_id => @document.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      delete :destroy, :document_id => @document.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end
  end

  protected

  def assert_attributes(response, expected_attributes = {})
    %w(id mp3_stream_url created_at).each do |key|
      assert response.has_key?(key), "should containt key '#{key}' in '#{response}'"
    end
  end
end