require 'test_helper'

class Api::IngestsControllerTest < ActionController::TestCase
  setup do
    @user1              = FactoryGirl.create(:user)
    @user2              = FactoryGirl.create(:backend_user)

    @document1          = FactoryGirl.create(:document)
    @track1             = FactoryGirl.create(:track)
    @ingest1            = FactoryGirl.create(:media_ingest_as_audio, :document => @document1, :track => @track1)

    @document1.privacy  = [:"public"]
    @document1.user     = @user1
    @document1.tag_list = ["brown", "fox", "jumps", "over", "fence"]
    @document1.save

    @document2          = FactoryGirl.create(:document)
    @track2             = FactoryGirl.create(:track)
    @ingest2            = FactoryGirl.create(:media_ingest_as_audio, :document => @document2, :track => @track2)
    @document2.privacy  = [:"private"]
    @document2.user     = @user2
    @document2.tag_list = ["brown", "cats", "jump", "higher"]
    @document2.save

    sign_out :user
  end

  context "GET /api/ingests(.:format)" do
    should "be unauthorized without user" do
      get :index, params: {format: :json}
      assert_response :unauthorized
    end

    should "be unauthorized for none backend users" do
      sign_in @user1, scope: :user
      get :index, params: {format: :json}
      assert_response :unauthorized
    end

    should "all ingests when signed in as backend user" do
      sign_in @user2, scope: :user
      get :index, params: {format: :json}
      assert_response :success
      assert response_body.has_key?("ingests"), "should have root"
      assert_equal 2, response_body["ingests"].size, "should have one ingest"
      assert_attributes response_body["ingests"].first
    end

    context "token authentication" do
      context "with access_token parameter" do
        should "authenticate 'backend' user role" do
          @client_access = FactoryGirl.create(:client_access, user: @user2, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          get :index, params: {access_token: @client_access.uid, format: :json}
          assert_response :success
        end

        should "NOT authenticate user without 'backend' role" do
          @client_access = FactoryGirl.create(:client_access, user: @user1, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          get :index, params: {access_token: @client_access.uid, format: :json}
          assert_response :unauthorized
        end

        should "NOT authenticate client access without user" do
          @client_access = FactoryGirl.create(:client_access, access_status: Api::ClientAccess::ACCESS_STATUS_CLIENT)
          get :index, params: {access_token: @client_access.uid, format: :json}
          assert_response :unauthorized
        end
      end

      context "with 'Authorization' header" do
        should "authenticate 'backend' user role" do
          @client_access = FactoryGirl.create(:client_access, user: @user2, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          # @request.headers['HTTP_AUTHORIZATION'] = @client_access.uid
          @request.headers['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(@client_access.uid)
          get :index, params: {format: :json}
          assert_response :success
        end

        should "NOT authenticate user without 'backend' role" do
          @client_access = FactoryGirl.create(:client_access, user: @user1, access_status: Api::ClientAccess::ACCESS_STATUS_ACCOUNT)
          @request.headers['HTTP_AUTHORIZATION'] = @client_access.uid
          get :index, params: {format: :json}
          assert_response :unauthorized
        end

        should "NOT authenticate client access without user" do
          @client_access = FactoryGirl.create(:client_access, access_status: Api::ClientAccess::ACCESS_STATUS_CLIENT)
          @request.headers['HTTP_AUTHORIZATION'] = @client_access.uid
          get :index, params: {format: :json}
          assert_response :unauthorized
        end
      end
    end
  end

  context "GET /api/ingests/count(.:format)" do
    should "be unauthorized whithout any user" do
      get :count, params: {format: :json}
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in @user1, scope: :user
      get :count, params: {format: :json}
      assert_response :unauthorized
    end

    should "count ingests when backend user is signed in" do
      sign_in @user2, scope: :user
      get :count, params: {format: :json}
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal Ingest.count, response_body["count"], "should have count"
    end
  end

  context "GET /api/ingests/:id" do
    should "be unauthorized whithout any user" do
      get :show, params: {:id => @ingest1.id, format: :json}
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in @user1, scope: :user
      get :show, params: {:id => @ingest1.id, format: :json}
      assert_response :unauthorized
    end

    should "get ingest when signed in as backend user" do
      sign_in @user2, scope: :user
      get :show, params: {:id => @ingest2.id, format: :json}
      assert_response :success
      assert_attributes response_body["ingest"]
      assert_not_nil response_body["ingest"]["upload"], "expect upload"
      assert_not_nil response_body["ingest"]["upload"]["recorded_at"], "expect recorded_at"
      assert_not_nil response_body["ingest"]["upload"]["uid"], "expect uid"
      assert_not_nil response_body["ingest"]["document"], "expect document"
    end
  end

  context "PUT /api/ingests/:id(.:format)" do
    should "update ingest to forward stage as backend user" do
      sign_in @user2, scope: :user
      assert_equal :starting, @ingest2.state
      assert_equal :begin_stage, @ingest2.stage
      put :update, params: {:id => @ingest2.id, :ingest => {
        event: "forward_stage"
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal :harvest_stage, @ingest2.reload.stage
      assert_equal 10, @ingest2.reload.progress
    end

    should "change ingest state to 'started' via #status=" do
      sign_in @user2, scope: :user
      assert_equal :starting, @ingest2.state
      put :update, params: {:id => @ingest2.id, :ingest => {
        stage: "start", progress: 1, status: Ingest::STATE_STARTED
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal Ingest::STATE_STARTED, response_body["ingest"]["status"]
      assert_equal :started, @ingest2.reload.state
    end

    should "change ingest state to 'started' via #event=" do
      sign_in @user2, scope: :user
      assert_equal :starting, @ingest2.state
      put :update, params: {:id => @ingest2.id, :ingest => {
        progress: 1, event: "process"
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal Ingest::STATE_STARTED, response_body["ingest"]["status"]
      assert_equal :started, @ingest2.reload.state
    end

    should "update metadata attributes" do
      sign_in @user2, scope: :user
      put :update, params: {:id => @ingest2.id, :ingest => {
        file_type: "video/mp4",
        file_size: 1234567
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal "video/mp4", response_body["ingest"]["file_type"]
      assert_equal 1234567, response_body["ingest"]["file_size"]
    end

    should "trigger next stage via #trigger_stage_with=" do
      sign_in @user2, scope: :user
      @ingest2.update_attributes(aasm_state: "started", aasm_stage: "harvest_stage")
      assert_equal :started, @ingest2.state
      assert_equal :harvest_stage, @ingest2.stage
      Ingest::MediaIngest::TranscodeWorker.expects(:perform_workflow).with(@ingest2.id).once

      put :update, params: {:id => @ingest2.id, :ingest => {
        trigger: "#{@ingest2.stage}"
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal :started, @ingest2.reload.state
    end

    should "change update ingest with origin_url" do
      origin_url = "http://s3.amazonaws.com/vz-test-origin/z6bg6kevzy8f5shcnjjj"
      sign_in @user2, scope: :user
      assert_equal :starting, @ingest2.state
      put :update, params: {:id => @ingest2.id, :ingest => {
        origin_url: origin_url
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "ingest"
      assert_equal origin_url, @ingest2.reload.origin_url
    end

    should "NOT change ingest state due to invalid transition via #status=" do
      sign_in @user2, scope: :user
      assert_equal :starting, @ingest2.state
      put :update, params: {:id => @ingest2.id, :ingest => {
        progress: 1, status: Ingest::STATE_RESET
      }, format: :json}
      assert_response :unprocessable_entity
      assert_equal true, response_body.has_key?("errors")
      assert_equal true, response_body["errors"].has_key?("status")
      assert_equal ["cannot transition from state 'starting'"], response_body["errors"]["status"]
      assert_equal :starting, @ingest2.reload.state
    end

    should "NOT update without user" do
      put :update, params: {:id => @ingest1.id, :ingest => {:stage => "transcribe"}, format: :json}
      assert_response :unauthorized
    end

    should "NOT update without backend user" do
      sign_in @user1, scope: :user
      put :update, params: {:id => @ingest1.id, :ingest => {:stage => "transcribe"}, format: :json}
      assert_response :unauthorized
    end
  end

  context "DELETE /api/ingests/:id(.:format)" do
    should "be unauthorized without user" do
      delete :destroy, params: {id: @ingest1, format: :json}
      assert_response :unauthorized
    end

    should "be unauthorized without backend user" do
      sign_in @user1, scope: :user
      delete :destroy, params: {id: @ingest1, format: :json}
      assert_response :unauthorized
    end

    should "destroy with backend user" do
      sign_in @user2, scope: :user
      assert_enqueued_with(job: Ingest::RemoveJob) do
        delete :destroy, params: {id: @ingest1, format: :json}
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
      progress stage stages iteration busy terminate uid locale events source_url file_name file_type file_size metadata use_source_annotations handle origin_url)).each do |attribute|
      assert params.has_key?(attribute), "should contain key '#{attribute}' in response '#{params}'"
    end

    expected_attributes.each do |key, value|
      assert_equal value, params[key], "'#{key}' should contain '#{value}', but was '#{params[key]}'"
    end
  end
end
