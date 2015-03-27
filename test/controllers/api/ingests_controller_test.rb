require 'test_helper'

class Api::IngestsControllerTest < ActionController::TestCase
  setup do
    @user1              = FactoryGirl.create(:user)
    @user2              = FactoryGirl.create(:backend_user)

    @document1          = FactoryGirl.create(:document)
    @track1             = FactoryGirl.create(:track)
    @ingest1            = FactoryGirl.create(:ingest_audio, :ingestable => @document1, :track_id => @track1.id)

    @document1.privacy  = [:"public"]
    @document1.user     = @user1
    @document1.tag_list = ["brown", "fox", "jumps", "over", "fence"]
    @document1.save

    @document2          = FactoryGirl.create(:document)
    @track2             = FactoryGirl.create(:track)
    @ingest2            = FactoryGirl.create(:ingest_audio, :ingestable => @document2, :track_id => @track2.id)
    @document2.privacy  = [:"private"]
    @document2.user     = @user2
    @document2.tag_list = ["brown", "cats", "jump", "higher"]
    @document2.save

    sign_out :user
  end

  context "GET /api/ingests" do
    should "be unauthorized without user" do
      get :index, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized for none backend users" do
      sign_in :user, @user1
      get :index, format: :json
      assert_response :unauthorized
    end

    should "all public documents when not signed in" do
      sign_in :user, @user2
      get :index, format: :json
      assert_response :success
      assert response_body.has_key?("ingests"), "should have root"
      assert_equal 4, response_body["ingests"].size, "should have one ingest"
      assert_attributes response_body["ingests"].first
    end
  end

  protected

  def assert_attributes(params, expected_attributes = {})
    (expected_attributes.keys + %w(id upload_id ingestable_id ingestable_type type status
      updated_at created_at started_at stopped_at restarted_at reset_at removed_at finished_at
      progress messages stage iteration busy track_id terminate)).each do |attribute|
      assert params.has_key?(attribute), "should containt key '#{attribute}' in response '#{params}'"
    end

    expected_attributes.each do |key, value|
      assert_equal value, params[key], "'#{key}' should contain '#{value}', but was '#{params[key]}'"
    end
  end
end
