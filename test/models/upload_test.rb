require 'test_helper'

class UploadTest < ActiveSupport::TestCase
  context "class" do
    should "#class_name_from_content_type_for" do
      assert_equal nil, Upload.class_name_from_content_type_for("foo/bar")
    end
  end

  context "associations" do
    should have_one(:ingest)
  end

  context "validations" do
    should validate_presence_of :file_name
    should ensure_length_of(:file_name).is_at_most(255)
    should validate_presence_of :file_type
    should ensure_length_of(:file_type).is_at_most(255)
    should validate_presence_of :s3_url
    should ensure_length_of(:s3_url).is_at_most(255)

    should "validate presence of title on update" do
      upload = Upload.create(type: "audio", file_name: "audio-test.m4a", file_type: "audio/x-m4a",
        file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio-test.m4a")
      assert_equal upload.humanized_file_name, upload.title
      upload.title = ""
      assert_equal false, upload.valid?
      assert_equal ["can't be blank"], upload.errors[:title]
    end
  end

  context "callbacks" do
    should "before_validation :set_title, on: :create" do
      upload = Upload.new(type: "audio", file_name: "audio.m4a", file_type: "audio/x-m4a",
        file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio.m4a")
      assert_equal upload.humanized_file_name, upload.title
      assert_equal true, upload.save
      upload.reload
      assert_equal "Audio", upload.title
    end
  end

  context "scopes" do
    setup do
      @upload = FactoryGirl.create(:upload_audio)
    end

    should "have filtered scopes" do
      assert_equal [:any_of_status, :none_of_status, :sort_order, :reverse_sort, :offset, :limit].to_set,
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
  end # context "scopes"

  context "delegate" do
    setup do
      @upload = Upload.create(type: "audio", file_name: "audio.m4a", file_type: "audio/x-m4a",
        file_size: 12345, s3_url: "http://s3.amazonaws.com/dropbox/audio.m4a")
    end

    should delegate :user, to: :ingest
    should delegate :user=, to: :ingest
    should delegate :privacy, to: :ingest, allow_nil: true
    should delegate :privacy=, to: :ingest, allow_nil: true
    should delegate :status, to: :ingest
    should delegate :state, to: :ingest
    should delegate :slug, to: :ingest
    should delegate :progress, to: :ingest
    should delegate :title, to: :ingest, allow_nil: true
    should delegate :title=, to: :ingest, allow_nil: true
    should delegate :description, to: :ingest, allow_nil: true
    should delegate :description=, to: :ingest, allow_nil: true
    should delegate :locale, to: :ingest, allow_nil: true
    should delegate :locale=, to: :ingest, allow_nil: true
    should delegate :tag_list, to: :ingest, allow_nil: true
    should delegate :tag_list=, to: :ingest, allow_nil: true

    should "delegate :user" do
      assert_equal @upload.ingest.document.user, @upload.user
    end

    should "delegate :user=" do
      user = FactoryGirl.create(:user)
      @upload.user = user
      assert_equal true, @upload.save
      @upload = Upload.find_by_id(@upload.id)
      assert_equal user, @upload.user
    end

    should "delegate :privacy" do
      assert_equal ["public"], @upload.privacy
      assert_equal @upload.ingest.document.privacy, @upload.privacy
    end

    should "delegate :status" do
      assert_equal @upload.ingest.status, @upload.status
    end

    should "delegate :state" do
      assert_equal @upload.ingest.state, @upload.state
    end

    should "delegate :slug" do
      assert_equal @upload.ingest.document.slug, @upload.slug
    end

    should "delegate :title" do
      assert_equal @upload.ingest.document.title, @upload.title
    end

    should "delegate :title=" do
      @upload.title = "A new title"
      assert_equal "A new title", @upload.ingest.document.title
    end

    should "delegate :description" do
      assert_equal @upload.ingest.document.description, @upload.description
    end

    should "delegate :description=" do
      @upload.description = "A new description"
      assert_equal "A new description", @upload.ingest.document.description
    end

    should "delegate :tag_list" do
      assert_equal @upload.ingest.document.tag_list, @upload.tag_list
    end

    should "delegate :tag_list=" do
      @upload.tag_list = ["a", "new", "tag", "list"]
      assert_equal ["a", "new", "tag", "list"], @upload.ingest.document.tag_list
    end

    should "delegate :locale" do
      assert_equal @upload.ingest.document.locale, @upload.locale
    end

    should "delegate :locale=" do
      @upload.locale = "it-IT"
      assert_equal "it-IT", @upload.ingest.document.locale
    end
  end # context "delegate"

  should "humanize file name" do
    assert_equal "I like pickles", Upload::AudioUpload.new(file_name: "i_like_pickles.m4a").humanized_file_name
    assert_equal "I like pickles", Upload::AudioUpload.new(file_name: "i-like-pickles.m4a").humanized_file_name
  end

  should "have s3_key" do
    upload = FactoryGirl.create(:upload_audio, :s3_url => "http://s3.amazonaws.com/dropbox/61glI7mwmN")
    assert_equal "61glI7mwmN", upload.s3_key
  end

  should "generate object name" do
    assert_equal 10, Upload.generate_object_name.length
  end

  should "tell if locale has recently changed" do
    upload = FactoryGirl.create(:upload_audio, :s3_url => "http://s3.amazonaws.com/dropbox/61glI7mwmN")
    assert_equal false, upload.has_locale_recently_changed?
    upload.locale = "de-DE"
    assert_equal true, upload.has_locale_recently_changed?
  end

  should "destroy" do
    upload = FactoryGirl.create(:upload_audio, :s3_url => "http://s3.amazonaws.com/dropbox/61glI7mwmN")
    assert upload.ingest, "should have an ingest"
    ingest = upload.ingest
    assert_difference "Upload.count", -1 do
      assert_enqueued_with(job: Upload::DeleteJob) do
        upload.destroy
      end
      ingest.reload
      assert_equal :removing, ingest.state
    end
  end

  should "have uid" do
    upload = FactoryGirl.create(:upload_audio)
    assert_not_nil upload.uid
    assert_equal 36, upload.uid.length
  end

  should "have recorded_at timestamp" do
    recorded_time = Time.zone.now - 1.year
    upload = FactoryGirl.create(:upload_audio, recorded_at: recorded_time)
    assert_equal recorded_time, upload.recorded_at

    upload = FactoryGirl.create(:upload_audio, recorded_at: nil)
    assert_equal upload.created_at, upload.recorded_at
  end

  should "destroy" do
    upload = FactoryGirl.create(:upload_audio)
    assert_enqueued_with(job: Upload::DeleteJob) do
      upload.destroy
    end
    assert_equal :removing, upload.ingest.reload.state
  end
end
