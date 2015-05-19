require 'test_helper'

class IngestTest < ActiveSupport::TestCase
  should "build subclass with type" do
    assert_equal "Ingest::AudioIngest", Ingest.new(type: "audio").class.name
    assert_equal "Ingest::AudioIngest", Ingest.new(type: "audio_ingest").class.name
    assert_equal "Ingest::AudioIngest", Ingest.new(type: "Ingest::AudioIngest").class.name
  end

  context "associations" do
    should belong_to(:upload).dependent(:destroy)
    should belong_to(:document)
    should have_many(:chunks).through(:document)
    should have_many(:tracks).through(:chunks)
    should have_many(:ingest_chunks).dependent(:nullify)
  end

  context "validations" do
    should validate_presence_of(:upload).on(:create)
    should_not validate_presence_of(:upload).on(:update)
    should validate_presence_of :document
  end

  context "class" do
    should "#queue_name_for" do
      Ingest::STAGES.each do |name, value|
        assert_equal "#{name.to_s.upcase}_TEST_QUEUE", Ingest::queue_name_for(name)
      end
    end
  end

  context "delegate" do
    setup do
      @ingest = FactoryGirl.create(:ingest_audio)
    end

    should "#track to document" do
      assert_equal @ingest.document.track, @ingest.track
    end
  end

  context "scopes" do
    setup do
      @ingest = FactoryGirl.create(:ingest_audio)
    end

    should "have filtered scopes" do
      assert_equal [:any_of_status, :none_of_status, :sort_order, :reverse_sort,
        :offset, :limit, :document_id].to_set,
        Ingest.scopes.to_set
    end

    should "#any_of_status" do
      @ingest.update_attribute(:aasm_state, "started")
      assert_equal [@ingest], Ingest.any_of_status([Ingest::STATE_STARTED])
    end

    should "#none_of_status" do
      @ingest.update_attribute(:aasm_state, "started")  # :started = 2
      assert_equal [@ingest], Ingest.none_of_status([0, 1, 3, 4, 5, 6, 7, 8, 9, 10])
    end

    should "#sort_order" do
      @ingest.update_attribute(:aasm_state, "started")  # :started = 2
      assert_equal [@ingest], Ingest.sort_order("created_at" => "asc").reverse_sort("true").limit(1)
    end

    should "#document_id" do
      assert_equal [@ingest], Ingest.document_id(@ingest.document.id)
    end
  end # context "scopes"

  context "state machine" do
    should "have state and status" do
      ingest = FactoryGirl.create(:ingest_audio)
      assert_equal :created, ingest.state
      assert_equal 0, ingest.status
    end

    should "remove" do
      ingest = FactoryGirl.create(:ingest_audio)
      Ingest::RemoveWorker.jobs.clear
      assert_equal true, ingest.remove!, "should be able to event remove"
      assert_equal 1, Ingest::RemoveWorker.jobs.size
    end

    should "remove when upload is destroyed" do
      upload = FactoryGirl.create(:upload_audio)
      ingest = upload.ingest
      Ingest::RemoveWorker.jobs.clear
      assert_no_difference "Ingest.count" do
        assert_difference "Upload.count", -1 do
          upload.destroy
          assert_equal :removing, ingest.state
          assert_equal true, ingest.process!, "should be able to process"
          assert_equal :removed, ingest.state
        end
      end
    end

    should "transition on status=2" do
      ingest = FactoryGirl.create(:ingest_audio, :terminate => true, :busy => true)
      assert_equal :created, ingest.state
      ingest.status = Ingest::STATE_STARTING
      assert_equal true, ingest.save
      assert_equal :starting, ingest.reload.state
      ingest.status = Ingest::STATE_STARTED
      assert_equal true, ingest.save
      assert_equal :started, ingest.reload.state
    end

    should "events should transition states" do
      ingest = FactoryGirl.create(:ingest_audio, :terminate => true, :busy => true)
      assert_equal :created, ingest.state
      ingest.start!
      assert_equal :starting, ingest.state
      assert_equal false, ingest.terminate?
      assert_equal false, ingest.busy?
      ingest.process!
      assert_equal :started, ingest.state
      assert_not_nil ingest.started_at
      ingest.log! :started, "working"
      ingest.update_attributes(stage: "transcoding")
      FactoryGirl.create(:chunk, :document => ingest.document)
      assert_equal 0, ingest.iteration
      assert_equal false, ingest.messages.empty?

      ingest.clear_terminate!
      assert_equal false, ingest.terminate?
      ingest.restart!
      assert_equal :restarting, ingest.state
      assert_equal true, ingest.terminate?
      assert_equal false, ingest.messages.empty?
      ingest.process!
      assert_equal :started, ingest.state
      assert_equal true, ingest.messages.empty?
      assert_nil ingest.stage
      # ingest.process!
      # assert_equal :started, ingest.state
      # ingest.log! :started, "working"
      ingest.update_attributes(stage: "copy_object")

      ingest.clear_terminate!
      assert_equal false, ingest.terminate?
      ingest.stop!
      assert_equal :stopping, ingest.state
      assert_equal true, ingest.terminate?
      ingest.process!
      assert_equal :stopped, ingest.state
      assert_not_nil ingest.stopped_at

      ingest.start!
      assert_equal :starting, ingest.state
      ingest.process!
      assert_equal :started, ingest.state
      assert_not_nil ingest.started_at

      ingest.stop!
      assert_equal :stopping, ingest.state
      ingest.process!
      assert_equal :stopped, ingest.state
      assert_not_nil ingest.stopped_at

      ingest.clear_terminate!
      assert_equal false, ingest.terminate?
      ingest.reset!
      assert_equal :resetting, ingest.state
      assert_equal true, ingest.terminate?
      ingest.process!
      assert_equal :reset, ingest.state
      assert_not_nil ingest.reset_at
      assert_equal 2, ingest.iteration

      ingest.start!
      assert_equal :starting, ingest.state
      ingest.process!
      assert_equal :started, ingest.state
      assert_not_nil ingest.started_at

      ingest.finish!
      assert_equal :finished, ingest.state
      assert_not_nil ingest.finished_at

      ingest.remove!
      assert_equal :removing, ingest.state
      ingest.process!
      assert_equal :removed, ingest.state
      assert_not_nil ingest.removed_at
    end

    should "event setter to force and events getter to receive permissible events" do
      ingest = FactoryGirl.create(:ingest_audio, :terminate => true, :busy => true)
      assert_equal :created, ingest.state
      ingest.event = "start"
      assert_equal :starting, ingest.state
      assert_equal [:remove, :restart], ingest.events

      ingest = FactoryGirl.create(:ingest_audio, :terminate => true, :busy => true)
      assert_equal :created, ingest.state
      ingest.event = :start
      assert_equal :starting, ingest.state
    end
  end

  should "log message" do
    ingest = FactoryGirl.create(:ingest_audio)
    ingest.log! :copy, "File not found."
    assert_equal ["File not found."], ingest.messages["copy"]
    ingest.log! :transcode, "Service unavailable."
    assert_equal ["Service unavailable."], ingest.messages["transcode"]
    ingest.log! 'transcode', "Unsufficient disk space."
    assert_equal ["Service unavailable.", "Unsufficient disk space."], ingest.messages["transcode"]
  end

  should "set progress" do
    ingest = FactoryGirl.create(:ingest_audio)
    ingest.set_progress!(5) and ingest.reload
    assert_equal 5, ingest.progress
    ingest.set_progress!(75.5) and ingest.reload
    assert_equal 76, ingest.progress
    ingest.set_progress!(101) and ingest.reload
    assert_equal 100, ingest.progress
  end

  should "increment progress" do
    ingest = FactoryGirl.create(:ingest_audio)
    ingest.set_progress!(10) and ingest.reload
    assert_equal 10, ingest.progress
    175.times do |index|
      ingest.increment_progress! 1, 175, 80
    end
    assert_equal 90, ingest.progress
    ingest.increment_progress! 1, 175, 80
    assert_equal 90, ingest.progress
  end

  should "calculate average score and duration" do
    ingest = FactoryGirl.create(:ingest_audio)
    document = ingest.document
    chunk1 = FactoryGirl.create(:chunk, :offset => 0, :document => document, :score => 0)
    chunk2 = FactoryGirl.create(:chunk, :offset => 1, :document => document, :score => 0.5)
    chunk3 = FactoryGirl.create(:chunk, :offset => 2, :document => document, :score => 1)
    assert_equal 3, ingest.chunks.count
    assert_equal 0.5, ingest.score.to_f
    assert_equal 10.53, ingest.duration.to_f
  end

  should "order chunks by offset" do
    ingest = FactoryGirl.create(:ingest_audio)
    document = ingest.document
    chunk3 = FactoryGirl.create(:chunk, :offset => 2, :document => document, :score => 1)
    chunk1 = FactoryGirl.create(:chunk, :offset => 0, :document => document, :score => 0)
    chunk2 = FactoryGirl.create(:chunk, :offset => 1, :document => document, :score => 0.5)
    assert_equal 3, ingest.chunks.count
    chunks = ingest.chunks.order(:offset)
    assert_equal chunk1, chunks[0]
    assert_equal chunk2, chunks[1]
    assert_equal chunk3, chunks[2]
  end

  context "chunks" do
    setup do
      @ingest = FactoryGirl.create(:ingest_audio)
      @document = @ingest.document
      Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I hate to say", :score => 0.80, :document => @document, :ingest => @ingest)
      Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "that macaronies are", :score => 0.65, :document => @document, :ingest => @ingest)
      Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the best food in the world", :score => 0.85, :document => @document, :ingest => @ingest)

      Chunk::AttSpeechChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I have to pray", :score => 0.70, :document => @document, :ingest => @ingest)
      Chunk::AttSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "cat maths are", :score => 0.70, :document => @document, :ingest => @ingest)
      Chunk::AttSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the best mushrooms in the whirlwind.", :score => 0.95, :document => @document, :ingest => @ingest)

      Chunk::NuanceDragonChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I have say", :score => 0, :document => @document, :ingest => @ingest)
      Chunk::NuanceDragonChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "that some macaronies are", :score => 0, :document => @document, :ingest => @ingest)
      Chunk::NuanceDragonChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the cesty food in the world", :score => 0, :document => @document, :ingest => @ingest)
    end

    should "normalize chunk scores" do
      assert_equal "the best mushrooms in the whirlwind.", @ingest.chunks.order(score: :desc).first.text
      @ingest.normalize_chunk_scores!
      assert_equal "the best food in the world", @ingest.chunks.order(score: :desc).first.text
    end

    should "update from chunks" do
      @ingest.normalize_chunk_scores!
      @ingest.update_content_from @ingest.chunks.best
      rich_text = @ingest.document.rich_text
      assert_equal 3, rich_text.size
      assert_equal "I hate to say", rich_text[0]['insert']
      assert_equal "that macaronies are", rich_text[1]['insert']
      assert_equal "the best food in the world", rich_text[2]['insert']
    end
  end

  should "have uid" do
    @ingest = FactoryGirl.create(:ingest_audio)
    assert_not_nil @ingest.uid
    assert_equal 36, @ingest.uid.length
  end
end
