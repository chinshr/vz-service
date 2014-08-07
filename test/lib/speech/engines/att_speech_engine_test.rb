require 'test_helper'

class Speech::Engines::AttSpeechEngineTest < ActiveSupport::TestCase
  setup do
    WebMock.disable_net_connect!
  end
  
  context "standard mode" do
    setup do
      # oauth
      stub_request(:post, "https://api.att.com/oauth/token").
        to_return(:status => 200, :body => {"access_token"=>"hsb9TM57GiMwtqmqZlBExLmDgDS59fQS", "token_type"=>"bearer", "expires_in"=>157680000, "refresh_token"=>"MwVMzXhL3177gaCVSfsjCJV1cWvN5mHg"}.to_json, :headers => {})

      # post
      stub_request(:post, "https://api.att.com/speech/v3/speechToText").
         to_return(status: 200, headers: {}, body: {"Recognition"=>{"Info"=>{"metrics"=>{"audioBytes"=>112620, "audioTime"=>3.50999999}}, "NBest"=>[{"Confidence"=>1, "Grade"=>"accept", "Hypothesis"=>"i like pickles", "LanguageId"=>"en-US", "ResultText"=>"I like pickles.", "WordScores"=>[1, 1, 1], "Words"=>["I", "like", "pickles."]}], "ResponseId"=>"5a0c7dceecc5b581d8b4a1ca7e204203", "Status"=>"OK"}}.to_json)
    end

    should "convert audio to json" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav", 
        :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", 
        :mode => "standard", :verbose => false)
      json = audio.to_json
      assert_equal true, json.has_key?("chunks")
      assert_equal 1, json["chunks"].size
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, json["chunks"].first["status"]
      assert_equal 1, json["chunks"].first["hypotheses"].size
    end

    should "convert audio to json with block" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav", 
        :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", 
        :mode => "standard", :verbose => false)
      audio.to_json do |chunk|
        assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, chunk.status
        assert_equal "I like pickles.", chunk.best_text
        assert_equal 1, chunk.best_score
        assert_equal 1, chunk.id
        assert_equal 0, chunk.offset
        assert_equal 3.52, chunk.duration
        assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, JSON.parse(chunk.captured_json)['status']
        assert_equal [], chunk.errors
      end
    end
  end
  
  context "custom mode" do
    setup do
      # oauth
      stub_request(:post, "https://api.att.com/oauth/token").
        to_return(:status => 200, :body => {"access_token"=>"hsb9TM67GiMwtqmqZlBExLmDgDS59fQS", "token_type"=>"bearer", "expires_in"=>157680000, "refresh_token"=>"MwVMzXhL8177gaCVSfsjCJV1cWvN5mHg"}.to_json, :headers => {})

      # post
      stub_request(:post, "https://api.att.com/speech/v3/speechToTextCustom").
         to_return(status: 200, headers: {}, body: {"Recognition"=>{"Info"=>{"metrics"=>{"audioBytes"=>112620, "audioTime"=>3.50999999}}, "NBest"=>[{"Confidence"=>1, "Grade"=>"accept", "Hypothesis"=>"i like pickles", "LanguageId"=>"en-US", "ResultText"=>"I like pickles.", "WordScores"=>[1, 1, 1], "Words"=>["I", "like", "pickles."]}], "ResponseId"=>"5a0c7dceecc5b581d8b4a1ca7e204203", "Status"=>"OK"}}.to_json)
    end

    should "convert audio to json" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav", 
        :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", 
        :mode => "custom", :verbose => false)
      json = audio.to_json
      assert_equal true, json.has_key?("chunks")
      assert_equal 1, json["chunks"].size
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, json["chunks"].first["status"]
      assert_equal 1, json["chunks"].first["hypotheses"].size
    end
  end
end
