require 'test_helper'

class Speech::Engines::GoogleSpeechEngineTest < ActiveSupport::TestCase
  setup do
    stub_request(:post, "https://www.google.com/speech-api/v1/recognize?client=speech2text&lang=en-US&maxresults=2&xjerr=1").
    to_return(status: 200, headers: {}, body: {
      "status"=>0,"id"=>"ce178ea89f8b17d8e8298c9c7814700a-1",
      "hypotheses"=>[
        {"utterance"=>"I like pickles", "confidence"=>0.59408695}, 
        {"utterance"=>"I like turtles"}, 
        {"utterance"=>"I like tickles"}, 
        {"utterance"=>"I like to Kohl's"}, 
        {"utterance"=>"I Like tickles"}, 
        {"utterance"=>"I lyk tickles"}, 
        {"utterance"=>"I liked to Kohl's"}
      ]}.to_json)
  end

  should "convert audio to text" do
    audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav",
    :engine => :google_speech_engine, :verbose => false)
    assert_equal "I like pickles", audio.to_text
  end

  should "convert audio to json" do
    audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav",
    :engine => :google_speech_engine, :verbose => false)
    json = audio.to_json
    assert_equal true, json.has_key?("chunks")
    assert_equal 1, json["chunks"].size
    assert_equal 3, json["chunks"].first["status"]
    assert_equal 7, json["chunks"].first["hypotheses"].size
  end

  should "convert audio to json with block" do
    audio = Speech::AudioToText.new("#{Rails.root}/test/fixtures/i-like-pickles.wav",
    :engine => :google_speech_engine, :verbose => false)
    audio.to_json do |chunk|
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, chunk.status
      assert_equal "I like pickles", chunk.best_text
      assert_equal 0.59408695, chunk.best_score
      assert_equal 1, chunk.id
      assert_equal 0, chunk.offset
      assert_equal 3.52, chunk.duration
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, JSON.parse(chunk.captured_json)['status']
      assert_equal [], chunk.errors
    end
  end
end
