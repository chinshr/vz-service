require 'test_helper'

class Speech::Engines::NuanceDragonEngineTest < ActiveSupport::TestCase
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
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_TRANSCRIBED, JSON.parse(chunk.captured_json)['status']
      assert_equal [], chunk.errors
    end
  end
end
