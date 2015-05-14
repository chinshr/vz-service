require 'test_helper'

class Api::IngestsControllerTest < ActionController::TestCase
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

  context "GET /api/ingests(.:format)" do
    should "be unauthorized without user" do
      get :index, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized for none backend users" do
      sign_in :user, @user1
      get :index, format: :json
      assert_response :unauthorized
    end

    should "all ingests when signed in as backend user" do
      sign_in :user, @user2
      get :index, format: :json
      assert_response :success
      assert response_body.has_key?("ingests"), "should have root"
      assert_equal 4, response_body["ingests"].size, "should have one ingest"
      assert_attributes response_body["ingests"].first
    end

    context "token authentication" do
      context "with access_token parameter" do
        should "authenticate 'backend' user role" do
          @client_access = FactoryGirl.create(:client_access, user: @user2, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          get :index, access_token: @client_access.uid, format: :json
          assert_response :success
        end

        should "NOT authenticate user without 'backend' role" do
          @client_access = FactoryGirl.create(:client_access, user: @user1, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          get :index, access_token: @client_access.uid, format: :json
          assert_response :unauthorized
        end

        should "NOT authenticate client access without user" do
          @client_access = FactoryGirl.create(:client_access, access_status: Api::ClientAccess::ACCESS_STATUS_CLIENT)
          get :index, access_token: @client_access.uid, format: :json
          assert_response :unauthorized
        end
      end

      context "with 'Authorization' header" do
        should "authenticate 'backend' user role" do
          @client_access = FactoryGirl.create(:client_access, user: @user2, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          # @request.headers['HTTP_AUTHORIZATION'] = @client_access.uid
          @request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(@client_access.uid)
          get :index, format: :json
          assert_response :success
        end

        should "NOT authenticate user without 'backend' role" do
          @client_access = FactoryGirl.create(:client_access, user: @user1, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          @request.headers['HTTP_AUTHORIZATION'] = @client_access.uid
          get :index, format: :json
          assert_response :unauthorized
        end

        should "NOT authenticate client access without user" do
          @client_access = FactoryGirl.create(:client_access, access_status: Api::ClientAccess::ACCESS_STATUS_CLIENT)
          @request.headers['HTTP_AUTHORIZATION'] = @client_access.uid
          get :index, format: :json
          assert_response :unauthorized
        end
      end
    end
  end

  context "GET /api/ingests/count(.:format)" do
    should "be unauthorized whithout any user" do
      get :count, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :count, format: :json
      assert_response :unauthorized
    end

    should "count ingests when backend user is signed in" do
      sign_in :user, @user2
      get :count, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal Ingest.count, response_body["count"], "should have count"
    end
  end

  context "GET /api/ingests/:id" do
    should "be unauthorized whithout any user" do
      get :show, :id => @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      get :show, :id => @ingest1.id, format: :json
      assert_response :unauthorized
    end

    should "get ingest when signed in as backend user" do
      sign_in :user, @user2
      get :show, :id => @ingest2.id, format: :json
      assert_response :success
      assert_attributes response_body["ingest"]
      assert_not_nil response_body["ingest"]["audio_upload"], "expect upload"
      assert_not_nil response_body["ingest"]["document"], "expect document"
    end
  end

  context "PUT /api/ingests/:id(.:format)" do
    should "update ingest with backend user" do
      sign_in :user, @user2
      put :update, {:id => @ingest2.id, :ingest => {
        stage: "transcribe", progress: 5
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal "transcribe", @ingest2.reload.stage
      assert_equal 5, @ingest2.reload.progress
    end

    should "change ingest state to 'started' via #status=" do
      sign_in :user, @user2
      @ingest2.start!
      assert_equal :starting, @ingest2.state
      put :update, {:id => @ingest2.id, :ingest => {
        stage: "start", progress: 1, status: Ingest::STATE_STARTED
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal Ingest::STATE_STARTED, response_body["ingest"]["status"]
      assert_equal :started, @ingest2.reload.state
    end

    should "NOT change ingest state due to invalid transition via #status=" do
      sign_in :user, @user2
      assert_equal :created, @ingest2.state
      put :update, {:id => @ingest2.id, :ingest => {
        stage: "start", progress: 1, status: Ingest::STATE_RESET
      }, format: :json}
      assert_response :unprocessable_entity
      assert_equal :created, @ingest2.reload.state
    end

    should "NOT update without user" do
      put :update, {:id => @ingest1.id, :ingest => {:stage => "transcribe"}, format: :json}
      assert_response :unauthorized
    end

    should "NOT update without backend user" do
      sign_in :user, @user1
      put :update, {:id => @ingest1.id, :ingest => {:stage => "transcribe"}, format: :json}
      assert_response :unauthorized
    end
  end

  context "DELETE /api/ingests/:id(.:format)" do
    should "be unauthorized without user" do
      delete :destroy, {id: @ingest1, format: :json}
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in :user, @user1
      delete :destroy, {id: @ingest1, format: :json}
      assert_response :unauthorized
    end

    should "destroy with backend user" do
      sign_in :user, @user2
      assert_difference 'Ingest.count', -1 do
        delete :destroy, {id: @ingest1, format: :json}
        assert_response :success
        assert_attributes response_body["ingest"]
      end
    end
  end

  protected

  def assert_attributes(params, expected_attributes = {})
    assert_equal false, params.blank?, "response should not be empty"
    (expected_attributes.keys + %w(id upload_id document_id type status
      updated_at created_at started_at stopped_at restarted_at reset_at removed_at finished_at
      progress messages stage iteration busy terminate uid)).each do |attribute|
      assert params.has_key?(attribute), "should contain key '#{attribute}' in response '#{params}'"
    end

    expected_attributes.each do |key, value|
      assert_equal value, params[key], "'#{key}' should contain '#{value}', but was '#{params[key]}'"
    end
  end
end
