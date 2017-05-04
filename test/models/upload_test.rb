require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:user)
    should have_one(:ingest)
  end

  context "validations" do
    should validate_presence_of :type
    should validate_presence_of :source_url
    should validate_length_of(:source_url).is_at_most(2048)
  end

  context "delegate" do
    setup do
      @upload = Upload::MediaUpload.create(file_name: "audio.m4a",
        file_type: "audio/x-m4a", file_size: 12345,
        source_url: "http://s3.amazonaws.com/vz-test-dropbox/audio.m4a")
    end

    should delegate :source_url, to: :ingest
    should "delegate :source_url, to: :ingest" do
      assert_equal @upload.ingest.source_url, @upload.source_url
    end

    should delegate :source_url=, to: :ingest
    should "delegate :source_url=, to: :ingest" do
      @upload.source_url = "http://www.example.com"
      assert_equal "http://www.example.com", @upload.source_url
    end

    should delegate :origin_url, to: :ingest
    should "delegate :origin_url, to: :ingest" do
      @upload.ingest.origin_url = "http://origin.url.example.com"
      assert_equal @upload.ingest.origin_url, @upload.origin_url
    end

    should delegate :handle, to: :ingest
    should "delegate :handle, to: :ingest" do
      assert_equal @upload.ingest.handle, @upload.handle
    end

    should delegate :file_name, to: :ingest
    should "delegate :file_name" do
      assert_equal @upload.ingest.file_name, @upload.file_name
    end

    should delegate :file_name=, to: :ingest
    should "delegate :file_name=" do
      @upload.file_name = "file1.mp3"
      assert_equal "file1.mp3", @upload.file_name
    end

    should delegate :file_type, to: :ingest
    should delegate :file_type=, to: :ingest

    should "delegate :file_type" do
      assert_equal @upload.ingest.file_type, @upload.file_type
    end

    should "delegate :file_type=" do
      @upload.file_type = "audio/mpeg"
      assert_equal "audio/mpeg", @upload.file_type
    end

    should delegate :file_size, to: :ingest
    should delegate :file_size=, to: :ingest

    should "delegate :file_size" do
      assert_equal @upload.ingest.file_size, @upload.file_size
    end

    should "delegate :file_size=" do
      @upload.file_size = 888
      assert_equal 888, @upload.file_size
    end

    should delegate :user, to: :ingest
    should delegate :user=, to: :ingest

    should "delegate :user" do
      @upload.user = FactoryGirl.build(:user)
      assert_equal @upload.ingest.user, @upload.user
    end

    should "delegate :user=" do
      user = FactoryGirl.create(:user)
      @upload.user = user
      assert_equal @upload.user, @upload.ingest.user
      assert_equal true, @upload.save
      @upload = Upload.find_by_id(@upload.id)
      assert_equal user, @upload.user
    end

    should delegate :metadata, to: :ingest
    should delegate :metadata=, to: :ingest

    should "delegate :metadata" do
      assert_equal @upload.ingest.metadata, @upload.metadata
    end

    should "delegate :metadata=" do
      @upload.metadata = {"target" => {"key" => "value"}}
      assert_equal({"target" => {"key" => "value"}}, @upload.metadata)
    end

    should delegate :events, to: :ingest
    should delegate :event=, to: :ingest

    should "delegate :events" do
      assert_equal @upload.ingest.events, @upload.events
    end

    should "delegate :event=" do
      assert_nothing_raised do
        @upload.event = :fail
      end
    end

    should delegate :progress, to: :ingest
    should "delegate :progress" do
      assert_equal @upload.ingest.progress, @upload.progress
    end

    should delegate :status, to: :ingest
    should "delegate :status" do
      assert_equal @upload.ingest.status, @upload.status
    end

    should delegate :state, to: :ingest
    should "delegate :state" do
      assert_equal @upload.ingest.state, @upload.state
    end

  end

  context "scopes" do
    setup do
      @upload = FactoryGirl.create(:media_upload_as_audio)
    end

    should "have filtered scopes" do
      assert_equal [:any_of_status, :none_of_status,
        :sort_order, :reverse_sort, :offset, :limit,
        :any_of_types, :none_of_types].to_set,
        Upload.scopes.to_set
    end

    should "have any_of_status" do
      @upload.ingest.update_attribute(:aasm_state, "started")
      assert_equal [@upload], Upload.any_of_status([1, 2])
    end

    should "have none_of_status" do
      @upload.ingest.update_attribute(:aasm_state, "started")  # :started = 2
      assert_equal [@upload], Upload.none_of_status([0, 1, 3, 4, 5, 6, 7, 8, 9, 10])
    end

    should "#any_of_types" do
      assert_equal @upload, Upload.any_of_types("media_upload").first
      assert_equal @upload, Upload.any_of_types("Upload::MediaUpload").first
    end

    should "#none_of_types" do
      assert_nil Upload.none_of_types("media_upload").first
      assert_nil Upload.none_of_types("Upload::MediaUpload").first
    end

    context "aasm scopes" do
      should "#started" do
        assert_equal [], Upload::MediaUpload.started
        @upload.ingest.update_attribute(:aasm_state, "started")
        assert_equal [@upload], Upload::MediaUpload.started
      end

      should "#stopped" do
        assert_equal [], Upload::MediaUpload.stopped
        @upload.ingest.update_attribute(:aasm_state, "stopped")
        assert_equal [@upload], Upload::MediaUpload.stopped
      end

      should "#reset" do
        assert_equal [], Upload::MediaUpload.reset
        @upload.ingest.update_attribute(:aasm_state, "reset")
        assert_equal [@upload], Upload::MediaUpload.reset
      end

      should "#removed" do
        assert_equal [], Upload::MediaUpload.removed
        @upload.ingest.update_attribute(:aasm_state, "removed")
        assert_equal [@upload], Upload::MediaUpload.removed
      end

      should "#finished" do
        assert_equal [], Upload::MediaUpload.finished
        @upload.ingest.update_attribute(:aasm_state, "finished")
        assert_equal [@upload], Upload::MediaUpload.finished
      end

      should "#most_recent" do
        assert_equal [@upload], Upload::MediaUpload.most_recent
        assert_equal [@upload], Upload::MediaUpload.most_recent(1)
        assert_equal [], Upload::MediaUpload.most_recent(0)
      end
    end # context "aasm scopes"
  end # context "scopes"

  should "generate object name" do
    assert_equal 10, Upload.generate_object_name.length
  end

  should "have uid" do
    upload = FactoryGirl.create(:media_upload_as_audio)
    assert_not_nil upload.uid
    assert_equal 36, upload.uid.length
  end

  should "have recorded_at timestamp" do
    recorded_time = Time.zone.now - 1.year
    upload = FactoryGirl.create(:media_upload_as_audio, recorded_at: recorded_time)
    assert_equal recorded_time, upload.recorded_at

    upload = FactoryGirl.create(:media_upload_as_audio, recorded_at: nil)
    assert_equal upload.created_at, upload.recorded_at
  end

  context "#destroy" do
    setup do
      @upload = FactoryGirl.create(:media_upload_as_audio)
    end

    should "act paranoid" do
      assert_difference "Upload.count", -1 do
        @upload.destroy
        assert_not_nil @upload.deleted_at
      end
    end

    should "remove ingest" do
      assert_enqueued_with(job: Ingest::RemoveJob) do
        @upload.destroy
      end
      assert_equal :removing, @upload.ingest.reload.state
    end

    should "perform delete job" do
      assert_enqueued_with(job: Upload::DeleteJob) do
        @upload.destroy
      end
    end
  end
end
