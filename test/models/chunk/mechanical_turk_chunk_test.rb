require 'test_helper'

CreateHit = Struct.new("CreateHit", :id, :url)

class Chunk::MechanicalTurkChunkTest < ActiveSupport::TestCase
  context "build" do
    setup do
      Segment.destroy_all
    end
=begin
    should "chunk with chunk_segment same as in turkee gem" do
      chunk0 = FactoryGirl.create(:chunk_pocketsphinx) # merged_chunk
      assert_difference "Segment::ChunkSegment.count" do
        mc = Chunk::MechanicalTurkChunk.new({"text" => "I like pickles",
          "document_id" => chunk0.id,
          "position" => chunk0.position,
          "offset" => chunk0.offset,
          "turkee_task_id" => chunk0.turkee_task_id
        })
        assert_equal true, mc.save
        assert_equal chunk0.document, mc.document
      end
    end

    should "chunk with sub chunks" do
      ch0 = FactoryGirl.create(:chunk_pocketsphinx)
      ch1 = FactoryGirl.create(:chunk_pocketsphinx)
      d1  = ch1.document
      ch2 = FactoryGirl.create(:chunk_pocketsphinx)
      d2  = ch2.document
      assert_difference "Segment::ChunkSegment.count", 2 do
        ch0.chunk_ids = [ch1.id, ch2.id]
        assert_equal [ch1, ch2].to_set, ch0.chunks.to_set
        assert_equal d1, ch1.document
        assert_equal d2, ch2.document
      end
    end
=end
    should "create mechanical_turk chunk from captcha chunk" do
      @ingest   = FactoryGirl.create(:ingest_audio)
      @document = @ingest.document

      @sc_t1    = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://sc_t1", duration: 2))
      @cc_t1    = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://cc_t1", duration: 6))

      sc1 = Chunk::PocketsphinxChunk.create({
        position: 1, text: "now the earth was formed this and empty",
        offset: 0.28, score: 0.45,
        document: @document, ingest: @ingest, track: @sc_t1
      })

      rc1 = FactoryGirl.create(:chunk_google_speech, score: 0.99,
        text: "I like pickles")

      cc1 = @ingest.chunks.create({
        type: "captcha_chunk", position: 1, offset: 0.28, score: 0.45,
        text: "now the earth was formed this and empty|I like pickles",
        document: sc1, ingest: @ingest, track: @cc_t1,
        chunk_ids: [sc1.id, rc1.id],
        turkee_task_id: 666
      })

      mt1 = Chunk::MechanicalTurkChunk.create({
        text: "now the earth was formless and empty i like pickles",
        document_id: cc1.id,
        position: cc1.position,
        offset: cc1.offset,
        turkee_task_id: cc1.turkee_task_id
      })

      assert_equal cc1, mt1.document
    end
  end

=begin
  context "class methods" do
    setup do
      @chunk = FactoryGirl.create(:chunk_with_ingest, uid: "ccb7093c-6d7a-4b31-aa1e-ccb84804a2e6")
    end

    should "#hit_form_url" do
      assert_equal "https://localhost:3000/mechanical_turk/documents/ccb7093c-6d7a-4b31-aa1e-ccb84804a2e6/chunks/new",
        Chunk::MechanicalTurkChunk.send(:hit_form_url, @chunk)
    end

    should "#turk_host" do
      assert_equal "https://localhost:3000",
        Chunk::MechanicalTurkChunk.send(:turk_host)
    end

    should "#hit_title" do
      assert_equal "Transcribe up to 25 Seconds of English audio to text - Earn up to $0.12 per HIT!",
        Chunk::MechanicalTurkChunk.send(:hit_title, @chunk)
    end

    should "#hit_description" do
      assert_equal "Press PLAY and type the words that you hear then press ENTER or Submit.",
        Chunk::MechanicalTurkChunk.send(:hit_description, @chunk)
    end

    should "#create_hit" do
      RTurk::Hit.stubs(:create).returns(CreateHit.new(1, "http"))
      assert_difference "Turkee::TurkeeTask.count", 1 do
        Chunk::MechanicalTurkChunk.create_hit(@chunk)
      end
    end

    should "#hit_complete" do
      turkee_task = FactoryGirl.create(:turkee_task)
      chunk = FactoryGirl.create(:chunk_mechanical_turk, turkee_task_id: turkee_task.id)
      Chunk::MechanicalTurkChunk.hit_complete(turkee_task)
      assert_equal Chunk::MechanicalTurkChunk::STATES[:transcribed],
        chunk.reload.processing_status
    end

    should "#hit_expired" do
      turkee_task = FactoryGirl.create(:turkee_task)
      chunk = FactoryGirl.create(:chunk_mechanical_turk, turkee_task_id: turkee_task.id)
      Chunk::MechanicalTurkChunk.hit_expired(turkee_task)
      assert_equal Chunk::MechanicalTurkChunk::STATES[:transcription_error],
        chunk.reload.processing_status
    end

    should "#process_hits" do
      turkee_task1 = FactoryGirl.create(:turkee_task)
      turkee_task2 = FactoryGirl.create(:turkee_task)
      chunk0 = FactoryGirl.create(:chunk_pocketsphinx)
      RTurk::Hit.stubs(:create).returns(CreateHit.new(1, "http"))
      Chunk::MechanicalTurkChunk.create_hit(chunk0)

      Turkee::TurkeeTask.stubs(:unprocessed_hits).returns([])
      Turkee::TurkeeTask.stubs(:map_imported_values).returns([Chunk::MechanicalTurkChunk,
        {"chunk_mechanical_turk_chunk" => {"text" => "I like pickles",
          "document_id" => chunk0.id, "position" => chunk0.position, "offset" => chunk0.offset,
          "turkee_task_id" => chunk0.turkee_task_id}}])

      assignment = Struct.new("Assignment", :id, :status, :worker_id) do
        def reject!(msg); @reject = msg; end
        def approve!(msg); @approve = msg; end
      end.new("2", "Submitted", "8")
      RTurk::Hit.any_instance.stubs(:assignments).returns([assignment])

      assert_difference "Chunk::MechanicalTurkChunk.count", 1 do
        assert_no_difference "Track.count" do
          Chunk::MechanicalTurkChunk.process_hits
          mtc = Chunk::MechanicalTurkChunk.last
          assert_equal chunk0.document, mtc.document
          assert_equal chunk0.position, mtc.position
          assert_equal chunk0.offset, mtc.offset
          assert_equal chunk0.duration, mtc.duration
          assert_equal chunk0.start_at, mtc.start_at
          assert_equal chunk0.end_at, mtc.end_at
          assert_equal chunk0.turkee_task_id, mtc.turkee_task_id
          assert_equal chunk0.locale, mtc.locale
          assert_equal chunk0.ingest_id, mtc.ingest_id
          assert_equal chunk0.ingest_iteration, mtc.ingest_iteration
          assert_equal chunk0.track, mtc.track
        end
      end
    end
  end
=end
end
