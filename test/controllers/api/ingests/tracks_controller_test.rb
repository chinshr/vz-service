require 'test_helper'

class Api::Ingests::TracksControllerTest < ActionController::TestCase
  setup do
    @user1    = FactoryGirl.create(:user)
    @user2    = FactoryGirl.create(:backend_user)

    @ingest   = FactoryGirl.create(:ingest_audio)
    @document = @ingest.document

    @t0 = @ingest.document.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t0", :ingest => @ingest)
    @c1 = Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :document => @ingest.document, :ingest => @ingest)
    @t1 = @c1.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t1")
    @c2 = Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.65, :document => @ingest.document, :ingest => @ingest)
    @t2 = @c2.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t2")
    @c3 = Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :text => "the cesty food in the world", :score => 0.85, :document => @ingest.document, :ingest => @ingest)
    @t3 = @c3.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t3")

    @s3_url     = "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4"
    @s3_mp3_url = "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4.128.mp3"
    @s3_waveform_json_url = "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t0-waveform.json"

    sign_out :user
  end

  context "POST /api/ingests/:ingest_id/tracks.json" do
    should "#create document master track via ingest" do
      sign_in :user, @user2
      post :create, ingest_id: @ingest.id, track: {
        s3_url: @s3_url, s3_mp3_url: @s3_mp3_url,
        s3_waveform_json_url: @s3_waveform_json_url,
        ingest_iteration: @ingest.iteration
      }, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal @s3_url, response_body["track"]["s3_url"]
      assert_equal @s3_mp3_url, response_body["track"]["s3_mp3_url"]
      assert_equal @ingest.id, response_body["track"]["ingest_id"]
      assert_equal @document.id, response_body["track"]["document_id"]
      assert_equal @ingest.iteration, response_body["track"]["ingest_iteration"]
      assert_equal @s3_waveform_json_url, response_body["track"]["s3_waveform_json_url"]
      assert_equal true, response_body["track"]["is_master"]
    end

    should "be unauthorized without user" do
      post :create, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      post :create, ingest_id: @ingest.id, format: :json
      assert_response :unauthorized
    end
  end

  context "PUT /api/ingests/:ingest_id/tracks/:id.json" do
    should "#update ingest/document master track" do
      sign_in :user, @user2
      put :update, ingest_id: @ingest.id, id: @t0.id, track: {
        s3_url: "http://update_t0", s3_mp3_url: "http://update_t0.128.mp3"}, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal "http://update_t0", response_body["track"]["s3_url"]
      assert_equal "http://update_t0.128.mp3", response_body["track"]["s3_mp3_url"]
    end

    should "be unauthorized without user" do
      put :update, ingest_id: @ingest.id, id: @t0.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      put :update, ingest_id: @ingest.id, id: @t0.id, format: :json
      assert_response :unauthorized
    end
  end

  context "GET /api/ingests/:ingest_id/tracks.json" do
    should "get index" do
      sign_in :user, @user2
      get :index, :ingest_id => @ingest.id, :is_master => "1", format: :json
      assert_response :success
      assert_equal 1, response_body["tracks"].size
      track = Track.find(response_body["tracks"].first["id"])
      assert_attributes response_body["tracks"].first, track
    end

    should "be unauthorized without user" do
      get :index, :ingest_id => @ingest.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :index, :ingest_id => @ingest.id, format: :json
      assert_response :unauthorized
    end
  end

  context "GET /api/ingests/:ingest_id/tracks/:id.json" do
    should "get show" do
      sign_in :user, @user2
      get :show, :ingest_id => @ingest.id, :id => @t0.id, format: :json
      assert_response :success
      assert_attributes response_body["track"]
    end

    should "be unauthorized without user" do
      get :show, :ingest_id => @ingest.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :show, :ingest_id => @ingest.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end
  end

  context "DELETE /api/ingests/:ingest_id/tracks/:id.json" do
    should "#delete" do
      sign_in :user, @user2
      assert_difference "Track.count", -1 do
        delete :destroy, :ingest_id => @ingest.id, :id => @t0.id, format: :json
        assert_response :success
        assert_response_body_attributes_with "track"
      end
    end

    should "be unauthorized without user" do
      delete :destroy, :ingest_id => @ingest.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      delete :destroy, :ingest_id => @ingest.id, :id => @t0.id, format: :json
      assert_response :unauthorized
    end
  end

  protected

  def assert_attributes(response, expected_attributes = {})
    %w(id mp3_stream_url created_at is_master ingest_id document_id ingest_iteration uid s3_url s3_key s3_mp3_url s3_mp3_key waveform_json_stream_url s3_waveform_json_key updated_at).each do |key|
      assert response.has_key?(key), "should contain key '#{key}' in '#{response}'"
    end
  end
end