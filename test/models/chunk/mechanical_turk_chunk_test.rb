require 'test_helper'

CreateHit = Struct.new("CreateHit", :id, :url)

class Chunk::MechanicalTurkChunkTest < ActiveSupport::TestCase
  context "build" do
    setup do
      Segment.destroy_all
    end

    should "chunk with chunk_segment same as in turkee gem" do
      chunk0 = FactoryGirl.create(:chunk_pocketsphinx) # merged_chunk
      assert_difference "Segment::ChunkSegment.count" do
        mt = Chunk::MechanicalTurkChunk.new({"text" => "I like pickles",
          "document_id" => chunk0.id,
          "position" => chunk0.position,
          "offset" => chunk0.offset,
          "turkee_task_id" => chunk0.turkee_task_id
        })
        assert_equal true, mt.save
        assert_equal chunk0, mt.document
        assert_equal true, chunk0.chunks.include?(mt)
      end
    end
  end

  context "approve Captcha based chunks" do
    setup do
      [Document, Segment, Track].each {|klass| klass.destroy_all}
      @ingest   = FactoryGirl.create(:media_ingest_as_audio)
      @document = @ingest.document

      @sc_t1    = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://sc_t1", duration: 2))
      @cc_t1    = Track.create(FactoryGirl.attributes_for(:track, type: "chunk_track", s3_url: "http://cc_t1", duration: 6))

      @sc1 = Chunk::PocketsphinxChunk.create({
        position: 1, text: "now the earth was formed this and empty",
        offset: 0.28, score: 0.45, ingest_iteration: 5,
        document: @document, ingest: @ingest, track: @sc_t1
      })

      @rc1 = FactoryGirl.create(:chunk_google_speech, score: 0.99,
        text: "I like pickles")

      Chunk::MechanicalTurkChunk.stubs(:create_hit).returns(true)

      @cc1 = @ingest.chunks.create({
        type: "captcha_chunk", position: 1, offset: 0.28, score: 0.45,
        text: "now the earth was formed this and empty|I like pickles",
        document: @sc1, ingest: @ingest, track: @cc_t1,
        chunk_ids: [@sc1.id, @rc1.id],
        turkee_task_id: 666
      })

      @mt1 = Chunk::MechanicalTurkChunk.create({
        text: "now the earth was formless and empty i like pickles",
        document_id: @cc1.id,
        position: @cc1.position,
        offset: @cc1.offset,
        turkee_task_id: @cc1.turkee_task_id
      })
    end

    should "check chunk integrity" do
      assert_equal @cc1, @mt1.document
      assert_equal true, @sc1.documents.include?(@cc1)
    end

    context "helpers" do
      should "#is_captcha_based?" do
        assert_equal true, @mt1.send(:is_captcha_based?)
      end

      should "#reference_chunks" do
        assert_equal [@rc1], @mt1.send(:reference_chunks)
      end

      should "#source_chunk" do
        assert_equal @sc1, @mt1.send(:source_chunk)
      end

      should "#captcha_confidence" do
        assert_equal 1.0, @mt1.send(:captcha_confidence)
      end
    end

    should "approve" do
      assert_equal true, @mt1.approve?
      assert_equal true, @document.chunks.include?(@mt1)
      assert_equal "now the earth was formless and empty", @mt1.text
      assert_equal 1.0, @mt1.score
    end
  end

  context "matcher helpers" do
    setup do
      @k = Chunk::MechanicalTurkChunk
    end

    should "#match_boundary" do
      l, r = @k.match_boundary("now the earth was formless and empty i like pickles", "i like pimples")
      assert_equal [37, 50], [l, r]
    end

    should "#match_confidence" do
      assert_equal 1.0, @k.match_confidence("now the earth i like pickles was formless and empty", "i like pickles")
      assert_equal 1.0, @k.match_confidence("i like pickles now the earth was formless and empty", "i like pickles")
      assert_equal true, @k.match_confidence("now the earth was formless and empty i like pickles", "i like pimples") > 0.84
    end

    should "#extract_truth" do
      # exact matches
      assert_equal "now the earth was formless and empty", @k.extract_truth("i like pickles now the earth was formless and empty", "i like pickles")
      assert_equal "now the earth was formless and empty", @k.extract_truth("now the earth was formless and empty i like pickles", "i like pickles")
      assert_equal "now the earth was formless and empty", @k.extract_truth("now the earth i like pickles was formless and empty", "i like pickles")

      # fuzzy matches
      assert_equal "now the earth was formless and empty", @k.extract_truth("i love pimples now the earth was formless and empty", "i like pickles")
      assert_equal "now the earth was formless and empty", @k.extract_truth("i like pickles now the earth was formless and empty", "i love pimples")
    end
  end

  context "class" do
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
        Chunk::MechanicalTurkChunk.process_hits
        mtc = Chunk::MechanicalTurkChunk.last
        assert_equal chunk0, mtc.document
        assert_equal chunk0.position, mtc.position
        assert_equal chunk0.offset, mtc.offset
      end
    end
  end
end

