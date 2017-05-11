require 'test_helper'

class IngestTest < ActiveSupport::TestCase
  should "build subclass with type" do
    assert_equal "Ingest::MediaIngest", Ingest.new(type: "media_ingest").class.name
    assert_equal "Ingest::MediaIngest", Ingest.new(type: "Ingest::MediaIngest").class.name
  end

  context "associations" do
    should belong_to(:upload).dependent(:destroy)
    should belong_to(:document)
    should have_many(:segments).dependent(:nullify)
    should have_many(:chunks).through(:segments)
    should have_many(:tracks).through(:chunks)
    should have_many(:workers).dependent(:destroy)
    should have_many(:servers).through(:workers)

    should "have_many uniq servers" do
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      server = FactoryGirl.create(:cpw_ingest_server)
      w1 = FactoryGirl.create(:ingest_worker, server: server, ingest: ingest)
      w2 = FactoryGirl.create(:ingest_worker, server: server, ingest: ingest)
      w3 = FactoryGirl.create(:ingest_worker, server: server, ingest: ingest)
      assert_equal 1, ingest.servers.to_a.size
    end

  end

  context "validations" do
    should validate_presence_of(:type)
    should_not validate_presence_of(:upload).on(:update)
  end

  context "delegate" do
    setup do
      @ingest = FactoryGirl.create(:media_ingest_as_audio)
    end

    should "#track to document" do
      assert_equal @ingest.document.track, @ingest.track
    end
  end

  context "scopes" do
    setup do
      @ingest = FactoryGirl.create(:media_ingest_as_audio)
    end

    should "have filtered scopes" do
      assert_equal [:any_of_status, :none_of_status, :sort_order, :reverse_sort,
        :offset, :limit, :document_id, :is_busy, :is_terminate].to_set,
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

    should "#is_busy" do
      assert_equal [], Ingest.is_busy(true)
      assert_equal [@ingest], Ingest.is_busy(false)
    end

    should "#is_terminate" do
      assert_equal [], Ingest.is_terminate(true)
      assert_equal [@ingest], Ingest.is_terminate(false)
    end
  end # context "scopes"

  context "state machine" do
    should "have state and status" do
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      assert_equal :starting, ingest.state
      assert_equal 1, ingest.status
    end

    should "#remove!" do
      ingest = FactoryGirl.create(:media_ingest_as_audio)
      assert_enqueued_with(job: Ingest::RemoveJob) do
        assert_equal true, ingest.remove!, "should be able to event remove"
      end
    end

    context "#status=" do
      should "transition to started from starting" do
        ingest = FactoryGirl.create(:media_ingest_as_audio, :terminate => true, :busy => true)
        assert_equal :starting, ingest.state
        ingest.status = Ingest::STATE_STARTED
        assert_equal true, ingest.save
        assert_equal :started, ingest.reload.state
        ingest.status = Ingest::STATE_FINISHED
        assert_equal true, ingest.save
        assert_equal :finished, ingest.reload.state
      end

      should "transition to finished from started" do
        ingest = FactoryGirl.create(:media_ingest_as_audio, :terminate => true, :busy => true)
        ingest.update_attributes(aasm_state: :started)
        ingest.status = Ingest::STATE_FINISHED
        assert_equal true, ingest.save
        assert_equal :finished, ingest.reload.state
      end

      should "transition to stopped from stopping" do
        ingest = FactoryGirl.create(:media_ingest_as_audio, :terminate => false, :busy => true)
        ingest.update_attributes(aasm_state: :started)
        assert_enqueued_with(job: Ingest::StopJob) do
          ingest.status = Ingest::STATE_STOPPING
          assert_equal true, ingest.save
        end
        assert_equal :stopping, ingest.reload.state
        assert_equal true, ingest.reload.terminate
        ingest.status = Ingest::STATE_STOPPED
        assert_equal true, ingest.save
        assert_equal :stopped, ingest.reload.state
        assert_equal false, ingest.terminate
      end

      should "transition to reset from resetting" do
        ingest = FactoryGirl.create(:media_ingest_as_audio, :terminate => true, :busy => true)
        ingest.update_attributes(aasm_state: :resetting)
        ingest.status = Ingest::STATE_RESET
        assert_equal true, ingest.save
        assert_equal :reset, ingest.reload.state
        assert_equal false, ingest.terminate
        assert_equal false, ingest.busy
      end

      should "transition to removed from removing" do
        ingest = FactoryGirl.create(:media_ingest_as_audio, :busy => false)
        ingest.update_attributes(aasm_state: :removing)
        ingest.status = Ingest::STATE_REMOVED
        assert_equal true, ingest.save
        assert_equal :removed, ingest.reload.state
      end
    end

    should "events should transition states" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, :terminate => true, :busy => true)
      ingest.update_attributes(aasm_state: "created")
      assert_equal :created, ingest.state
      ingest.start!
      assert_equal :starting, ingest.state
      assert_equal false, ingest.terminate?
      assert_equal false, ingest.busy?
      ingest.process!
      assert_equal :started, ingest.state
      assert_not_nil ingest.started_at
      ingest.log! :started, "working"
      ingest.update_attributes(aasm_stage: "transcode_stage")
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
      assert_equal "begin_stage", ingest[:aasm_stage]
      # ingest.process!
      # assert_equal :started, ingest.state
      # ingest.log! :started, "working"
      ingest.update_attributes(aasm_stage: "archive_stage")

      ingest.clear_terminate!
      assert_equal false, ingest.terminate?
      assert_enqueued_with(job: Ingest::StopJob) do
        ingest.stop!
      end
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
      assert_enqueued_with(job: Ingest::ResetJob) do
        ingest.reset!
      end
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
      assert_equal 100, ingest.progress

      ingest.remove!
      assert_equal :removing, ingest.state
      ingest.process!
      assert_equal :removed, ingest.state
      assert_not_nil ingest.removed_at
    end

    should "event setter to force and events getter to receive permissible events" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, :terminate => true, :busy => true)
      assert_equal :starting, ingest.state
      ingest.event = "process"
      assert_equal :started, ingest.state
      assert_equal true, ingest.events.include?(:stop)
      assert_equal true, ingest.events.include?(:remove)
      assert_equal true, ingest.events.include?(:process)
      assert_equal true, ingest.events.include?(:finish)
      assert_equal true, ingest.events.include?(:fail)
      assert_equal true, ingest.events.include?(:restart)

      ingest = FactoryGirl.create(:media_ingest_as_audio, :terminate => true, :busy => true)
      assert_equal :starting, ingest.state
      ingest.event = :process
      assert_equal :started, ingest.state
    end

  end # context :state_machine

  should "#stages" do
    assert_equal [], Ingest.new.stages
  end

  should "log message" do
    ingest = FactoryGirl.create(:media_ingest_as_audio)
    ingest.log! :copy, "File not found."
    assert_equal ["File not found."], ingest.messages["copy"]
    ingest.log! :transcode, "Service unavailable."
    assert_equal ["Service unavailable."], ingest.messages["transcode"]
    ingest.log! 'transcode', "Unsufficient disk space."
    assert_equal ["Service unavailable.", "Unsufficient disk space."], ingest.messages["transcode"]
  end

  should "set progress" do
    ingest = FactoryGirl.create(:media_ingest_as_audio)
    ingest.set_progress!(5) and ingest.reload
    assert_equal 5, ingest.progress
    ingest.set_progress!(75.5) and ingest.reload
    assert_in_delta 75.5, ingest.progress, 0.01
    ingest.set_progress!(101) and ingest.reload
    assert_equal 100, ingest.progress
  end

  context "inverse" do
    should "not be busy" do
      assert_equal false, Ingest.new(busy: true).not_busy?
      assert_equal true, Ingest.new(busy: false).not_busy?
    end

    should "not be terminated" do
      assert_equal false, Ingest.new(terminate: true).not_terminate?
      assert_equal true, Ingest.new(terminate: false).not_terminate?
    end

    should "not be 'created'" do
      assert_equal false, Ingest.new(aasm_state: 'created').not_created?
    end

    should "not be 'starting'" do
      assert_equal false, Ingest.new(aasm_state: 'starting').not_starting?
    end

    should "not be 'started'" do
      assert_equal false, Ingest.new(aasm_state: 'started').not_started?
    end

    should "not be 'stopping'" do
      assert_equal false, Ingest.new(aasm_state: 'stopping').not_stopping?
    end

    should "not be 'stopped'" do
      assert_equal false, Ingest.new(aasm_state: 'stopped').not_stopped?
    end

    should "not be 'resetting'" do
      assert_equal false, Ingest.new(aasm_state: 'resetting').not_resetting?
    end

    should "not be 'reset'" do
      assert_equal false, Ingest.new(aasm_state: 'reset').not_reset?
    end

    should "not be 'removing'" do
      assert_equal false, Ingest.new(aasm_state: 'removing').not_removing?
    end

    should "not be 'finished'" do
      assert_equal false, Ingest.new(aasm_state: 'finished').not_finished?
    end

    should "not be 'restarting'" do
      assert_equal false, Ingest.new(aasm_state: 'restarting').not_restarting?
    end
  end

  should "increment progress" do
    ingest = FactoryGirl.create(:media_ingest_as_audio)
    ingest.set_progress!(10) and ingest.reload
    assert_equal 10, ingest.progress
    175.times do |index|
      ingest.increment_progress! 1, 175, 80
    end
    assert_in_delta 90.5, ingest.progress, 0.001
    ingest.increment_progress! 1, 175, 80
    assert_in_delta 91, ingest.progress, 0.5
  end

  should "calculate average score and duration" do
    ingest = FactoryGirl.create(:media_ingest_as_audio)
    ch1 = ingest.chunks.create(FactoryGirl.attributes_for(:chunk_pocketsphinx, :offset => 0, :score => 0, :position => 1))
    ch2 = ingest.chunks.create(FactoryGirl.attributes_for(:chunk_pocketsphinx, :offset => 1, :score => 0.5, :position => 2))
    ch3 = ingest.chunks.create(FactoryGirl.attributes_for(:chunk_pocketsphinx, :offset => 2, :score => 1, :position => 3))
    assert_equal 3, ingest.chunks.count
    assert_equal 0.5, ingest.score.to_f
  end

  should "order chunks by offset" do
    ingest = FactoryGirl.create(:media_ingest_as_audio)
    ch3 = ingest.chunks.create(FactoryGirl.attributes_for(:chunk, :offset => 2, :score => 1, :position => 3))
    ch1 = ingest.chunks.create(FactoryGirl.attributes_for(:chunk, :offset => 0, :score => 0, :position => 1))
    ch2 = ingest.chunks.create(FactoryGirl.attributes_for(:chunk, :offset => 1, :score => 0.5, :position => 2))
    assert_equal 3, ingest.chunks.count
    chunks = ingest.chunks.order(:offset)
    assert_equal ch1, chunks[0]
    assert_equal ch2, chunks[1]
    assert_equal ch3, chunks[2]
  end

  context "chunks and tracks" do
    setup do
      Segment.destroy_all
      @ingest   = FactoryGirl.create(:media_ingest_as_audio)
      @document = @ingest.document

      @t0  = Track.create(FactoryGirl.attributes_for(:track, type: :document, s3_url: "http://t0"))
      @t1  = Track.create(FactoryGirl.attributes_for(:track, type: "chunk", s3_url: "http://t1"))
      @t2  = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://t2"))
      @t3  = Track.create(FactoryGirl.attributes_for(:track, type: :chunk_track, s3_url: "http://t3"))

      @document.update_attribute(:track, @t0)
      @document.master_segment.update_attribute(:ingest, @ingest)

      @gc1 = Chunk::GoogleSpeechChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I hate to say", :score => 0.80, :document => @document, :ingest => @ingest, :track => @t1)
      @gc2 = Chunk::GoogleSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "that macaronies are", :score => 0.65, :document => @document, :ingest => @ingest, :track => @t2)
      @gc3 = Chunk::GoogleSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the best food in the world", :score => 0.85, :document => @document, :ingest => @ingest, :track => @t3)

      @ac1 = Chunk::AttSpeechChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I have to pray", :score => 0.70, :document => @document, :ingest => @ingest, :track => @t1)
      @ac2 = Chunk::AttSpeechChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "cat maths are", :score => 0.70, :document => @document, :ingest => @ingest, :track => @t2)
      @ac3 = Chunk::AttSpeechChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the best mushrooms in the whirlwind.", :score => 0.95, :document => @document, :ingest => @ingest, :track => @t3)

      @nc1 = Chunk::NuanceDragonChunk.create(:position => 1, :offset => 0, :duration => 0.72, :text => "I have say", :score => 0, :document => @document, :ingest => @ingest, :track => @t1)
      @nc2 = Chunk::NuanceDragonChunk.create(:position => 2, :offset => 10, :duration => 0.89, :text => "that some macaronies are", :score => 0, :document => @document, :ingest => @ingest, :track => @t2)
      @nc3 = Chunk::NuanceDragonChunk.create(:position => 3, :offset => 20, :duration => 1.21, :text => "the cesty food in the world", :score => 0, :document => @document, :ingest => @ingest, :track => @t3)
    end

    should "chunk and track integrity" do
      assert_equal 1, Segment::DocumentSegment.count
      assert_equal 9, Segment::ChunkSegment.count
      assert_equal 9, @ingest.chunks.count
      assert_equal 3, @ingest.tracks.count
      assert_equal 4, @ingest.tracks_including_master_track.count
      assert_equal @t0, @ingest.track
      assert_equal [@t1, @t2, @t3].to_set, @ingest.tracks.to_set
      assert_equal [@t0, @t1, @t2, @t3].to_set, @ingest.tracks_including_master_track.to_set
      assert_equal [@gc1, @gc2, @gc3].to_set, @ingest.chunks.any_of_types(:google_speech).to_set
      assert_equal @t2, @ac2.track
      assert_equal @document, @t0.document
      assert_equal @ingest, @t0.reload.ingest
      assert_equal [@gc1, @ac1, @nc1].to_set, @t1.chunks.to_set
      assert_equal [@gc2, @ac2, @nc2].to_set, @t2.chunks.to_set
      assert_equal [@gc3, @ac3, @nc3].to_set, @t3.chunks.to_set
    end

    should "normalize chunk scores" do
      assert_equal "the best mushrooms in the whirlwind.", @ingest.chunks.order(score: :desc).first.text
      @ingest.normalize_chunk_scores!
      assert_equal "the best food in the world", @ingest.chunks.order(score: :desc).first.text
    end

    should "update from chunks" do
      @ingest.normalize_chunk_scores!
      @ingest.update_content_from @ingest.document.best_chunks
      rich_text = @ingest.document.best_chunks.rich_text
      assert_equal 5, rich_text['ops'].size, "includes spaces"
      assert_equal "I hate to say", rich_text['ops'][0]['insert']
      assert_equal "that macaronies are", rich_text['ops'][2]['insert']
      assert_equal "the best food in the world", rich_text['ops'][4]['insert']
    end
  end

  should "have uid" do
    @ingest = FactoryGirl.create(:media_ingest_as_audio)
    assert_not_nil @ingest.uid
  end

  should "create chunks through ingest" do
    @ingest = FactoryGirl.create(:media_ingest_as_audio)
    @chunk1 = @ingest.chunks.create(FactoryGirl.attributes_for(:chunk_pocketsphinx).merge(position: 1))
    assert_equal @ingest, @chunk1.reload.ingest
    assert_equal @ingest.document, @chunk1.reload.document
    assert_equal 1, @chunk1.reload.position
  end

  context "stop servers" do
    setup do
      @ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started")
      @server = FactoryGirl.create(:cpw_ingest_server)
    end

    should "when finished" do
      @ingest.update_attributes(aasm_state: "started")
      # assert_enqueued_with(job: Ingest::Server::StopJob) do
        assert_equal true, @ingest.finish!
      # end
      assert_equal :finished, @ingest.state
    end

    should "when stopped" do
      @ingest.update_attributes(aasm_state: "stopping")
      # assert_enqueued_with(job: Ingest::Server::StopJob) do
        assert_equal true, @ingest.process!
      # end
      assert_equal :stopped, @ingest.state
    end
  end

  context "#handle" do
    should "set handle if not S3 and not present" do
      ingest = Ingest.new
      ingest.valid?
      assert_equal 20, ingest.handle.length
    end

    should "derive handle from S3 upload URL" do
      ingest = Ingest.new(source_url: "http://s3.amazonaws.com/vz-test-dropbox/61glI7mwmN")
      ingest.valid?
      assert_equal "61glI7mwmN", ingest.handle
    end

    should "use assigned handle" do
      ingest = Ingest.new(handle: "abcd1234")
      ingest.valid?
      assert_equal "abcd1234", ingest.handle
    end
  end

  context "broadcast" do
    should "#refresh_upload on create" do
      ingest = FactoryGirl.build(:media_ingest_as_audio, aasm_state: "started",
        upload: FactoryGirl.build(:media_upload_as_audio))
      assert_broadcast :refresh_upload do
        ingest.save
      end
    end

    should "#refresh_upload on state change" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started")
      assert_broadcast :refresh_upload do
        ingest.finish!
      end
    end

    should "#refresh_upload on progress change" do
      ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started")
      assert_broadcast :refresh_upload do
        ingest.update_attribute(:progress, 99)
      end
    end

    # should "NOT #refresh_upload on touch" do
    #   ingest = FactoryGirl.create(:media_ingest_as_audio, aasm_state: "started")
    #   assert_broadcast :refresh_upload do
    #     ingest.touch
    #   end
    # end
  end

  context "#destroy" do
    setup do
      @ingest = FactoryGirl.create(:media_ingest_as_audio)
    end

    should "be paranoid" do
      assert_difference "Ingest.count", -1 do
        @ingest.destroy
        assert_not_nil @ingest.deleted_at
      end
    end

    should "schedule ingest delete job" do
      assert_enqueued_with(job: Ingest::DeleteJob) do
        @ingest.destroy
      end
    end

    should "delete dependent records" do
      assert_difference "Ingest.count", -1 do
        assert_difference "Upload.count", -1 do
          @ingest.destroy
        end
      end
    end
  end

  should "have upload" do
    media_ingest = FactoryGirl.create(:media_ingest_as_audio)
    assert_equal true, media_ingest.send(:has_upload?)
    assert_equal false, Ingest::ImageIngest.new.send(:has_upload?)
  end

  context "#metadata" do
    setup { @ingest = FactoryGirl.create(:media_ingest_as_audio) }

    should "traverse" do
      assert_not_nil @ingest.metadata
      assert_equal "Ingest::Metadata", @ingest.metadata.class.name
      assert_equal "Ingest::Metadata::Config", @ingest.metadata.config.class.name
      assert_equal "Ingest::Metadata::Config::Transcription", @ingest.metadata.config.transcription.class.name
      assert_nil @ingest.metadata.config.transcription.engine
      assert_nil @ingest.metadata.config.transcription.quality
    end

    should "set" do
      @ingest.metadata.config.transcription.engine = "test-engine"
      @ingest.metadata.config.transcription.quality = "high"
      assert_equal true, @ingest.save
      @ingest.reload
      assert_equal "test-engine", @ingest.metadata.config.transcription.engine
      assert_equal "high", @ingest.metadata.config.transcription.quality
    end
  end
end
