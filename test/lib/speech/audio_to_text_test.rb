require 'test_helper'

class Speech::AudioToTextTest < ActiveSupport::TestCase
  context "Nuance Dragon Engine" do
    setup do
      @base_url  = "https://dictation.nuancemobility.net:443"
      @app_id    = "NMDPTRIAL_chinshr20140326185635"
      @app_key   = "edb1acb2e50d02417b643e6dce510ea9dd565c4ad4725dcb8d807c96fe6304eb14b09ef9bea03a390578a6d3cab57ca70bd8f1df4b4eabd8cf276ecd8a72b99f&id=C4461956B60B"
      @device_id = "8CGoCMXyIcJosb2"
      stub_request(:post, "#{@base_url}/NMDPAsrCmdServlet/dictation?appId=#{@app_id}&appKey=#{@app_key}&id=#{@device_id}").
        to_return(status: 200, headers: {}, body: "I like pickles\n")
    end
  
    should "convert audio to text" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav", 
        :engine => :nuance_dragon_engine, :verbose => false, :base_url => @base_url, :app_id => @app_id, :app_key => @app_key)
      assert_equal "I like pickles", audio.to_text
    end
  
    should "convert audio to json" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav", 
        :engine => :nuance_dragon_engine, :verbose => false, :base_url => @base_url, :app_id => @app_id, :app_key => @app_key)
      json = audio.to_json
      assert_equal true, json.has_key?("chunks")
      assert_equal 1, json["chunks"].size
      assert_equal 3, json["chunks"].first["status"]
      assert_equal 1, json["chunks"].first["hypotheses"].size
    end

    should "convert audio to json with block" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav", 
        :engine => :nuance_dragon_engine, :verbose => false, :base_url => @base_url, :app_id => @app_id, :app_key => @app_key)
      audio.to_json do |chunk|
        assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, chunk.status
        assert_equal "I like pickles", chunk.best_text
        assert_equal 1, chunk.id
        assert_equal 0, chunk.offset
        assert_equal 3.52, chunk.duration
        assert_equal false, chunk.captured_json.empty?
        assert_equal [], chunk.errors
      end
    end
  end

  context "Google Speech Engine" do
    setup do
      stub_request(:post, "https://www.google.com/speech-api/v1/recognize?client=speech2text&lang=en-US&maxresults=2&xjerr=1").
        to_return(status: 200, headers: {}, body: {"status"=>0,"id"=>"ce178ea89f8b17d8e8298c9c7814700a-1",
          "hypotheses"=>[
            {"utterance"=>"I like pickles", "confidence"=>0.59408695}, 
            {"utterance"=>"I like turtles"}, {"utterance"=>"I like tickles"}, 
            {"utterance"=>"I like to Kohl's"}, {"utterance"=>"I Like tickles"}, 
            {"utterance"=>"I lyk tickles"}, {"utterance"=>"I liked to Kohl's"}]}.to_json)
    end
  
    should "convert audio to text" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav",
        :engine => :google_speech_engine, :locale => "en-US", :verbose => false)
      assert_equal "I like pickles", audio.to_text
    end
  
    should "convert audio to json" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav",
        :engine => :google_speech_engine, :locale => "en-US", :verbose => false)
      json = audio.to_json
      assert_equal true, json.has_key?("chunks")
      assert_equal 1, json["chunks"].size
      assert_equal 3, json["chunks"].first["status"]
      assert_equal 7, json["chunks"].first["hypotheses"].size
    end

    should "convert audio to json with block" do
      audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav",
        :engine => :google_speech_engine, :locale => "en-US", :verbose => false)
      audio.to_json do |chunk|
        assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, chunk.status
        assert_equal "I like pickles", chunk.best_text
        assert_equal 0.59408695, chunk.best_score
        assert_equal 1, chunk.id
        assert_equal 0, chunk.offset
        assert_equal 3.52, chunk.duration
        assert_equal false, chunk.captured_json.empty?
        assert_equal [], chunk.errors
      end
    end
  end

  context "ATT Speech Engine" do
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
          assert_equal false, chunk.captured_json.empty?
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
end
