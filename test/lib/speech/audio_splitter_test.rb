require 'test_helper'

class Speech::AudioSplitterTest < ActiveSupport::TestCase

  should "split audio into flac chunks" do
    splitter = Speech::AudioSplitter.new("#{Rails.root}/test/fixtures/i-like-pickles.wav")

    assert_equal '00:00:03.52', splitter.duration.to_s
    assert_equal 3.52, splitter.duration.to_f

    chunks = splitter.split
    assert_equal 1, chunks.size
    chunks.each do|chunk|
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_BUILT, chunk.status  # built because there is only one chunk
      chunk.build
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_BUILT, chunk.status
      chunk.to_flac
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_ENCODED, chunk.status
      assert chunk.to_flac_bytes
      assert_equal 46540, chunk.flac_size
      
      assert_equal [], chunk.errors
      assert File.exist? chunk.chunk
      assert File.exist? chunk.flac_chunk
      chunk.clean
      assert !File.exist?(chunk.chunk)
      assert !File.exist?(chunk.flac_chunk)
    end
  end

  should "split audio into wav chunks" do
    splitter = Speech::AudioSplitter.new("#{Rails.root}/test/fixtures/i-like-pickles.wav")

    assert_equal '00:00:03.52', splitter.duration.to_s
    assert_equal 3.52, splitter.duration.to_f

    chunks = splitter.split
    assert_equal 1, chunks.size
    chunks.each do|chunk|
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_BUILT, chunk.status  # built because there is only one chunk
      chunk.build
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_BUILT, chunk.status
      chunk.to_wav
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_ENCODED, chunk.status
      assert chunk.to_wav_bytes
      assert_equal 112698, chunk.wav_size
      
      assert_equal [], chunk.errors
      assert File.exist? chunk.chunk
      assert File.exist? chunk.wav_chunk
      chunk.clean
      assert !File.exist?(chunk.chunk)
      assert !File.exist?(chunk.wav_chunk)
    end
  end

  should "split audio into raw chunks" do
    splitter = Speech::AudioSplitter.new("#{Rails.root}/test/fixtures/i-like-pickles.wav")

    assert_equal '00:00:03.52', splitter.duration.to_s
    assert_equal 3.52, splitter.duration.to_f

    chunks = splitter.split
    assert_equal 1, chunks.size
    chunks.each do|chunk|
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_BUILT, chunk.status  # built because there is only one chunk
      chunk.build
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_BUILT, chunk.status
      chunk.to_raw
      assert_equal Speech::AudioSplitter::AudioChunk::STATUS_ENCODED, chunk.status
      assert chunk.to_raw_bytes
      assert_equal 112620, chunk.raw_size
      
      assert_equal [], chunk.errors
      assert File.exist? chunk.chunk
      assert File.exist? chunk.raw_chunk
      chunk.clean
      assert !File.exist?(chunk.chunk)
      assert !File.exist?(chunk.raw_chunk)
    end
  end

end
