require 'test_helper'

class Api::Ingests::ChunksControllerTest < ActionController::TestCase
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

    @s3_url     = "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4"
    @s3_mp3_url = "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4.128.mp3"
    @s3_waveform_json_url = "http://s3.amazonaws.com/vz-test-origin/13dba008-7ba2-4804-a534-43d03c65260b/t4.128.waveform.json"

    @words = [{"p"=>1,"c"=>0.7,"s"=>1.610,"e"=>1.780,"w"=>"This"},{"p"=>2,"c"=>0.714,"s"=>1.780,"e"=>1.960,"w"=>"is"}]

    sign_out :user
  end

  context "POST /api/ingests/:ingest_id/chunks" do
    setup do
      @attributes = {
        :position          => 1,
        :offset            => 0,
        :text              => "I like pickles",
        :score             => 0.59,
        :response          => {"status" => 3, "hypotheses" => [{"utterance" => "I like pickles", "confidence" => 0.9876}], "words" => @words},
        :processing_status => 3,
        :ingest_iteration  => 1
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
      assert_difference 'Chunk::PocketsphinxChunk.count', 1 do
        attributes = @attributes.merge(type: "pocketsphinx")
        post :create, ingest_id: @ingest1.id, chunk: attributes, format: :json
        assert_response :success
        attributes[:type] = "Chunk::PocketsphinxChunk"
        assert_attributes response_body["chunk"], attributes
        assert_equal 1, Chunk::PocketsphinxChunk.last.ingest_iteration
        assert_equal true, response_body["chunk"].has_key?("response")
        assert_equal true, response_body["chunk"]["response"].has_key?("words")
        assert_equal true, response_body["chunk"]["response"].has_key?("hypotheses")
        assert_equal 1, response_body["chunk"]["response"]["hypotheses"].size
        assert_equal true, response_body["chunk"]["response"].has_key?("words")
        assert_equal 2, response_body["chunk"]["response"]["words"].size
      end
    end

    should "create chunk with ingest_iteration from associated ingest" do
      sign_in :user, @user2
      attributes = @attributes
      attributes.delete(:ingest_iteration)
      assert_difference 'Chunk::GoogleSpeechChunk.count', 1 do
        attributes = @attributes.merge(type: "Chunk::GoogleSpeechChunk")
        post :create, ingest_id: @ingest1.id, chunk: attributes, format: :json
        assert_response :success
        assert_attributes response_body["chunk"], attributes
        assert_equal @ingest1.iteration, Chunk::GoogleSpeechChunk.last.ingest_iteration
      end
    end

    should "create chunk with track_attributes" do
      sign_in :user, @user2
      assert_difference 'Chunk::GoogleSpeechChunk.count', 1 do
        assert_difference 'Track.count', 1 do
          attributes = @attributes.merge(type: "Chunk::GoogleSpeechChunk")
          track_attributes = {duration: 5, s3_url: @s3_url, s3_mp3_url: @s3_mp3_url, s3_waveform_json_url: @s3_waveform_json_url}
          post :create, ingest_id: @ingest1.id, chunk: attributes.merge(track_attributes: track_attributes), format: :json
          assert_response :success
          assert_attributes response_body["chunk"], attributes
          assert_equal 1, Chunk::GoogleSpeechChunk.last.ingest_iteration
          assert_not_nil response_body["chunk"]["track"]
          assert_equal @s3_url, response_body["chunk"]["track"]["s3_url"]
          assert_equal @s3_mp3_url, response_body["chunk"]["track"]["s3_mp3_url"]
          assert_equal @s3_waveform_json_url, response_body["chunk"]["track"]["s3_waveform_json_url"]
        end
      end
    end

    should "create captcha chunk with source and reference chunks" do
      sign_in :user, @user2

      Chunk::MechanicalTurkChunk.stubs(:create_hit).returns(true)

      assert_difference 'Chunk::CaptchaChunk.count', 1 do
        sc_t1 = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://sc_t1", duration: 2))
        sc1   = Chunk::PocketsphinxChunk.create({
          position: 1, text: "now the earth was formed this and empty",
          offset: 0.28, score: 0.45,
          document: @document1, ingest: @ingest1, track: sc_t1
        })
        rc1   = FactoryGirl.create(:chunk_google_speech, score: 0.99,
          text: "I like pickles")

        attributes = @attributes.merge(type: "Chunk::CaptchaChunk",
          document_id: sc1.id, chunk_ids: [sc1.id, rc1.id])
        track_attributes = {duration: 5, s3_url: @s3_url, s3_mp3_url: @s3_mp3_url, s3_waveform_json_url: @s3_waveform_json_url}
        post :create, ingest_id: @ingest1.id, chunk: attributes.merge(track_attributes: track_attributes), format: :json
        assert_response :success
        attributes[:chunk_ids] = response_body["chunk"]["chunk_ids"] # fixes order problem
        assert_attributes response_body["chunk"], attributes
        assert_equal sc1.id, response_body["chunk"]["document_id"]
        assert_equal [sc1.id, rc1.id].to_set, response_body["chunk"]["chunk_ids"].to_set
        assert_not_nil response_body["chunk"]["track"]
        assert_equal @s3_url, response_body["chunk"]["track"]["s3_url"]
        assert_equal @s3_mp3_url, response_body["chunk"]["track"]["s3_mp3_url"]
        assert_equal @s3_waveform_json_url, response_body["chunk"]["track"]["s3_waveform_json_url"]
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
      get :index, ingest_id: @ingest1.id, any_of_types: "att_speech", format: :json
      assert_response :success
      assert response_body.has_key?("chunks"), "should have root"
      assert_equal 1, response_body["chunks"].size, "should have one chunk"
      assert_attributes response_body["chunks"].first
    end
  end

  context "GET /api/ingests/chunks" do
    should "be unauthorized without user" do
      get :index, format: :json
      assert_response :unauthorized
    end

    should "be unauthorized for none backend users" do
      sign_in :user, @user1
      get :index, format: :json
      assert_response :unauthorized
    end

    should "filter ingest chunks of type att_speech" do
      Chunk.destroy_all
      @chunk1 = FactoryGirl.create(:chunk_pocketsphinx)
      @chunk2 = FactoryGirl.create(:chunk_pocketsphinx, document: @ingest1.document, ingest_id: @ingest1.id)
      sign_in :user, @user2
      get :index, none_of_ingest_ids: [@ingest1.id], any_of_types: ["pocketsphinx"],
        format: :json
      assert_response :success
      assert response_body.has_key?("chunks"), "should have root"
      assert_equal 1, response_body["chunks"].size, "should have one chunk"
      assert_attributes response_body["chunks"].first
      assert_equal @chunk1.id, response_body["chunks"].first["id"]
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
      count = 27
      count.times do |index|
        FactoryGirl.create(:chunk_google_speech, document: @ingest1.document,
          ingest_id: @ingest1.id, position: index + 1)
      end
      sign_in :user, @user2
      get :count, ingest_id: @ingest1.id, format: :json
      assert_response :success
      assert response_body.has_key?("count"), "should have root"
      assert_equal count, response_body["count"], "should have count"
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
        :response          => {"status" => 1, "hypotheses" => {"utterance" => "You got it!", "confidence" => 0.95}},
      }, format: :json}
      assert_response :success
      assert_response_body_attributes_with "chunk"
      assert_equal 0.95, @chunk1.reload.score
      assert_equal 1, @chunk1.response.status
      assert_equal "You got it!", @chunk1.response.hypotheses[0].utterance
    end

    should "update ingest with track_attributes to create new track" do
      sign_in :user, @user2
      attributes = {:score => 0.95,
        :response => {"status" => 1, "hypotheses" => {"utterance" => "You got it!", "confidence" => 0.95}},
      }
      track_attributes = {s3_url: @s3_url, s3_mp3_url: @s3_mp3_url}
      assert_no_difference 'Chunk::GoogleSpeechChunk.count' do
        assert_difference 'Track.count', 1 do
          put :update, {ingest_id: @ingest1.id, id: @chunk1.id,
            :chunk => attributes.merge(track_attributes: track_attributes), format: :json}
          assert_response :success
          assert_response_body_attributes_with "chunk"
          assert_equal 0.95, @chunk1.reload.score
          assert_equal 1, @chunk1.response.status
          assert_equal "You got it!", @chunk1.response.hypotheses[0].utterance
          assert_not_nil response_body["chunk"]["track"]
          assert_equal @s3_url, response_body["chunk"]["track"]["s3_url"]
          assert_equal @s3_mp3_url, response_body["chunk"]["track"]["s3_mp3_url"]
        end
      end
    end

    should "update ingest with track_attributes to update existing track" do
      sign_in :user, @user2
      attributes = {:score => 0.95,
        :response => {"status" => 1, "hypothesis" => "You got it!"},
      }
      track_attributes = {s3_url: @s3_url, s3_mp3_url: @s3_mp3_url}

      @track1 = @chunk1.create_track(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://track-12"))
      @chunk1.reload

      assert_no_difference 'Chunk::GoogleSpeechChunk.count' do
        assert_no_difference 'Track.count' do
          put :update, {ingest_id: @ingest1.id, id: @chunk1.id,
            :chunk => attributes.merge(track_attributes: track_attributes), format: :json}
          assert_response :success
          assert_response_body_attributes_with "chunk"
          assert_equal 0.95, @chunk1.reload.score
          assert_not_nil response_body["chunk"]["track"]
          assert_equal @s3_url, response_body["chunk"]["track"]["s3_url"]
          assert_equal @s3_mp3_url, response_body["chunk"]["track"]["s3_mp3_url"]
        end
      end
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
      assert_no_difference 'Chunk.count' do
        delete :destroy, {ingest_id: @ingest1.id, id: @chunk1.id, format: :json}
        assert_response :success
        assert_attributes response_body["chunk"]
          assert_equal 0, @ingest1.chunks.count
      end
    end
  end

  protected

  def assert_attributes(params, expected_attributes = {})
    assert_equal false, params.blank?, "response should not be empty"
    (expected_attributes.stringify_keys.keys + %w(id document_id ingest_id type position offset duration start_at
      end_at text score response processing_status uid ingest_iteration locale)).uniq.each do |attribute|
      assert params.has_key?(attribute), "should contain key '#{attribute}' in response '#{params}'"
    end

    expected_attributes.stringify_keys.each do |key, value|
      if key.to_s == "response"
      else
        assert_equal value, params[key], "'#{key}' attribute should contain '#{value}', but was '#{params[key]}'"
      end
    end
  end
end
