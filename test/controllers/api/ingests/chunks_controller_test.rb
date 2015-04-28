require 'test_helper'

class Api::Ingests::ChunksControllerTest < ActionController::TestCase
  setup do
    @user1              = FactoryGirl.create(:user)
    @user2              = FactoryGirl.create(:backend_user)

    @document1          = FactoryGirl.create(:document)
    @track1             = FactoryGirl.create(:track)
    @ingest1            = FactoryGirl.create(:ingest_audio, :document => @document1, :track => @track1)

    @document1.privacy  = [:"public"]
    @document1.user     = @user1
    @document1.tag_list = ["brown", "fox", "jumps", "over", "fence"]
    @document1.save

    @document2          = FactoryGirl.create(:document)
    @track2             = FactoryGirl.create(:track)
    @ingest2            = FactoryGirl.create(:ingest_audio, :document => @document2, :track => @track2)
    @document2.privacy  = [:"private"]
    @document2.user     = @user2
    @document2.tag_list = ["brown", "cats", "jump", "higher"]
    @document2.save

    sign_out :user
  end

  context "POST /api/ingests/:ingest_id/chunks" do
    setup do
      @attributes = {
        :position          => 1,
        :offset            => 0,
        :duration          => 5,
        :start_time        => 0.to_f,
        :end_time          => 5.to_f,
        :text              => "I like pickles",
        :score             => 0.59,
        :response          => {"status" => 3, "hypothesis" => "I like pickles"},
        :processing_errors => [{"stage" => "transcribe", "errors" => ["foo", "bar"]}],
        :processing_status => 3
      }
    end

    should "be unauthorized without user" do
      post :create, :ingest_id => @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      post :create, :ingest_id => @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "create chunk with signed in backend user" do
      sign_in :user, @user2
      assert_difference 'Chunk.count', 1 do
        attributes = @attributes.merge(type: "Chunk::GoogleSpeech")
        post :create, ingest_id: @ingest1.id, chunk: attributes, format: :json
        assert_response :success
        assert_attributes response_body["chunk"], attributes
      end
    end
  end

  context "GET /api/ingests/:ingest_id/chunks" do
    should "be unauthorized without user" do
      get :index, ingest_id: @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized for none backend users" do
      sign_in :user, @user1
      get :index, ingest_id: @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "all ingest chunks when signed in as backend user" do
      @chunk1 = FactoryGirl.create(:chunk_google_speech, document: @ingest1.document, ingest_id: @ingest1.id)
      sign_in :user, @user2
      get :index, ingest_id: @ingest1.id, format: :json
      assert_response :success
      assert response_body.has_key?("chunks"), "should have root"
      assert_equal 1, response_body["chunks"].size, "should have one chunk"
      assert_attributes response_body["chunks"].first
    end

    should "filter ingest chunks of type att_speech" do
      @chunk1 = FactoryGirl.create(:chunk_google_speech, document: @ingest1.document, ingest_id: @ingest1.id)
      @chunk2 = FactoryGirl.create(:chunk_att_speech, document: @ingest1.document, ingest_id: @ingest1.id)
      sign_in :user, @user2
      get :index, ingest_id: @ingest1.id, any_of_type: "att_speech", format: :json
      assert_response :success
      assert response_body.has_key?("chunks"), "should have root"
      assert_equal 1, response_body["chunks"].size, "should have one chunk"
      assert_attributes response_body["chunks"].first
    end
  end

  context "GET /api/ingests/:ingest_id/chunks/count" do
    should "be unauthorized whithout any user" do
      get :count, ingest_id: @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :count, ingest_id: @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "count ingest chunks when backend user is signed in" do
      @chunk1 = FactoryGirl.create(:chunk_google_speech, document: @ingest1.document, ingest_id: @ingest1.id)
      sign_in :user, @user2
      get :count, ingest_id: @ingest1.id, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal @ingest1.chunks.count, response_body["count"], "should have count"
    end
  end

  context "GET /api/ingests/:ingest_id/chunks/:id" do
    setup do
      @chunk1 = FactoryGirl.create(:chunk_google_speech, document: @ingest1.document, ingest_id: @ingest1.id)
    end

    should "be unauthorized whithout any user" do
      get :show, ingest_id: @ingest1.id, id: @chunk1.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :show, ingest_id: @ingest1.id, id: @chunk1.id, format: :json
      assert_response :unauthorized
    end

    should "get ingest when signed in as backend user" do
      sign_in :user, @user2
      get :show, ingest_id: @ingest1.id, id: @chunk1.id, format: :json
      assert_response :success
      assert_attributes response_body["chunk"]
      assert_equal @ingest1.id, response_body["chunk"]["ingest_id"]
      assert_equal @ingest1.document.id, response_body["chunk"]["document_id"]
    end
  end

  context "PUT /api/ingests/:ingest_id/chunks/:id" do
    setup do
      @chunk1 = FactoryGirl.create(:chunk_google_speech, document: @ingest1.document, ingest_id: @ingest1.id)
    end

    should "update ingest with backend user" do
      sign_in :user, @user2
      put :update, {ingest_id: @ingest1.id, id: @chunk1.id, :chunk => {
        :score             => 0.95,
        :response          => {"status" => 1, "hypothesis" => "You got it!"},
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "chunk"
      assert_equal 0.95, @chunk1.reload.score
      assert_equal({"status" => 1, "hypothesis" => "You got it!"}, @chunk1.reload.response)
    end

    should "NOT update without user" do
      put :update, {ingest_id: @ingest1.id, id: @chunk1.id, :chunk => {}, format: :json}
      assert_response :unauthorized
    end

    should "NOT update without backend user" do
      sign_in :user, @user1
      put :update, {ingest_id: @ingest1.id, id: @chunk1.id, :chunk => {}, format: :json}
      assert_response :unauthorized
    end
  end

  context "DELETE /api/ingests/:ingest_id/chunks/:id" do
    setup do
      @chunk1 = FactoryGirl.create(:chunk_google_speech, document: @ingest1.document, ingest_id: @ingest1.id)
    end

    should "be unauthorized without user" do
      assert_no_difference 'Chunk.count' do
        delete :destroy, {ingest_id: @ingest1.id, id: @chunk1.id, format: :json}
        assert_response :unauthorized
      end
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      assert_no_difference 'Chunk.count' do
        delete :destroy, {ingest_id: @ingest1.id, id: @chunk1.id, format: :json}
        assert_response :unauthorized
      end
    end

    should "destroy with backend user" do
      sign_in :user, @user2
      assert_difference 'Chunk.count', -1 do
        delete :destroy, {ingest_id: @ingest1.id, id: @chunk1.id, format: :json}
        assert_response :success
        assert_attributes response_body["chunk"]
      end
    end
  end

  protected

  def assert_attributes(params, expected_attributes = {})
    assert_equal false, params.blank?, "response should not be empty"
    (expected_attributes.stringify_keys.keys + %w(id document_id ingest_id type position offset duration start_time
      end_time text score response processing_errors processing_status uid)).uniq.each do |attribute|
      assert params.has_key?(attribute), "should contain key '#{attribute}' in response '#{params}'"
    end

    expected_attributes.stringify_keys.each do |key, value|
      assert_equal value, params[key], "'#{key}' attribute should contain '#{value}', but was '#{params[key]}'"
    end
  end
end
