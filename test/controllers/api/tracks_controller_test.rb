require 'test_helper'

class Api::TracksControllerTest < ActionController::TestCase
  setup do
    @document  = FactoryGirl.create(:document)
    @track1    = FactoryGirl.create(:track)
    @ingest1   = FactoryGirl.create(:ingest_audio, :ingestable => @document, :track_id => @track1.id)
    @track2    = FactoryGirl.create(:track)
    @ingest2   = FactoryGirl.create(:ingest_audio, :ingestable => @document, :track_id => @track2.id)
  end

  context "GET /api/documents/:document_id/tracks.json" do
    should "get index" do
      get :index, :document_id => @document.id, format: :json
      assert_response :success
      assert response_body.has_key?("tracks"), "should have root"
      assert_attributes response_body["tracks"].first
      assert_equal 2, response_body["tracks"].size
    end
  end

  context "GET /api/documents/:document_id/tracks/:id.json" do
    should "get show" do
      get :show, :document_id => @document.id, :id => @track1.id, format: :json
      assert_response :success
      assert_response_body_attributes_with "track"
    end
  end

  protected

  def assert_attributes(response, expected_attributes = {})
    %w(id mp3_stream_url created_at).each do |key|
      assert response.has_key?(key), "should containt key '#{key}' in '#{response}'"
    end
  end
end
