require 'test_helper'

class Api::Documents::TracksControllerTest < ActionController::TestCase
  setup do
    @user1    = FactoryGirl.create(:user)
    @user2    = FactoryGirl.create(:backend_user)

    @ingest   = FactoryGirl.create(:ingest_audio)
    @document = @ingest.document

    @t0 = @ingest.document.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t0")
    @c1 = Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0,  :text => "I hate to say", :score => 0.80, :document => @ingest.document, :ingest_id => @ingest.id)
    @t1 = @c1.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t1")
    @c2 = Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :text => "cat maths are", :score => 0.65, :document => @ingest.document, :ingest_id => @ingest.id)
    @t2 = @c2.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t2")
    @c3 = Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :text => "the cesty food in the world", :score => 0.85, :document => @ingest.document, :ingest_id => @ingest.id)
    @t3 = @c3.create_track(s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t3")

    sign_out :user
  end

=begin
  context "POST /api/documents/:document_id/tracks.json" do

    should "#create document master track" do
      sign_in :user, @user2
      post :create, document_id: @document.id, track: {s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4", 
        s3_mp3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4.128.mp3"}, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4", 
        response_body["track"]["s3_url"]
      assert_equal "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4.128.mp3",
        response_body["track"]["s3_mp3_url"]
    end

    should "#create chunk track" do
      sign_in :user, @user2
      post :create, document_id: @c1.id, track: {s3_url: "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/chunk-track1"}, format: :json
      assert_response :success
      assert_attributes response_body["track"]
      assert_equal "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/chunk-track1",
        response_body["track"]["s3_url"]
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
=end

=begin
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
=end

  context "GET /api/documents/:document_id/tracks.json" do
    should "get index" do
      sign_in :user, @user2
      get :index, :document_id => @document.id, :is_master => "1", format: :json
      assert_response :success
      assert_equal 1, response_body["tracks"].size
      assert_attributes response_body["tracks"].first, Track.find(response_body["tracks"].first["id"])
      assert_nil response_body["tracks"].first["s3_url"]
      assert_nil response_body["tracks"].first["s3_uri"]
      assert_nil response_body["tracks"].first["s3_key"]
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
      assert_attributes response_body["track"]
      assert_nil response_body["track"]["s3_url"]
      assert_nil response_body["track"]["s3_uri"]
      assert_nil response_body["track"]["s3_key"]
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

=begin
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
=end

  protected

  def assert_attributes(response, expected_attributes = {})
    %w(id mp3_stream_url waveform_json_stream_url is_master created_at).each do |key|
      assert response.has_key?(key), "should containt key '#{key}' in '#{response}'"
    end
  end

end