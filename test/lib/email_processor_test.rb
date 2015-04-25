require 'test_helper'

class EmailProcessorTest < ActiveSupport::TestCase
  setup do
    EmailProcessor.stubs(:upload_file_to_s3_bucket).returns(true)
    ActionMailer::Base.deliveries.clear

    attachment1 = ActionDispatch::Http::UploadedFile.new({
      :filename     => "sample.m4a",
      :content_type => "audio/x-m4a",
      :tempfile     => File.new("#{Rails.root}/test/fixtures/sample.m4a")
    })
    # attachment1.content_type = "audio/x-m4a"  # re-assign, doesn't work otherwise!

    @params = {
      "dkim"=>"none",
      "envelope"=>{"to"=>["my@app.example.com"], "from"=>"raj@example.com"},
      "to"=>"my@app.example.com", "from"=>"Raj Aakula <raj@example.com>", "sender_ip"=>"199.36.142.181",
      "subject"=>"Sample recording 1",
      "attachment-info"=>"{\"attachment1\":{\"filename\":\"sample.m4a\",\"name\":\"sample.m4a\",\"type\":\"audio/x-m4a\"}}",
      "charsets"=>"{\"to\":\"UTF-8\",\"subject\":\"UTF-8\",\"from\":\"UTF-8\"}",
      "headers"=>"Received: by mx-006.sjc1.sendgrid.net with ...",
      "attachment1"=>attachment1, "attachments"=>"1", "html" => "<i>Check this out!</i>"
    }
  end

  should "process message with attachments, signup user and send notifications" do
    assert_difference "User.count", 1 do
      assert_difference "Message.count", 1 do
        assert_difference "Upload.count", 1 do
          assert_difference "ActionMailer::Base.deliveries.size", 2 do
            normalized_params(@params).each do |p|
              Griddler::Email.new(p).process
            end
          end
        end
      end
    end

    assert_equal "Confirmation instructions", ActionMailer::Base.deliveries[0].subject
    assert_equal "We are working hard transcribing your message.", ActionMailer::Base.deliveries[1].subject
    assert_equal User.last, Message.last.sender
    assert_equal User.last, Upload.last.user
  end

  should "humanize audio file as upload title if no subject given" do
    @params.delete(:subject)
    normalized_params(@params).each do |p|
      Griddler::Email.new(p).process
    end
    assert_equal "Sample recording 1", Upload.last.title
  end

  should "parse locale from email address" do
    @params["to"] = "my+en-UK@app.example.com"
    normalized_params(@params).each do |p|
      Griddler::Email.new(p).process
    end
    assert_equal "en-UK", Upload.last.locale
  end

  should "process message with attachments, send notification" do
    FactoryGirl.create(:user, :email => "raj@example.com")
    ActionMailer::Base.deliveries.clear
    assert_difference "User.count", 0 do
      assert_difference "Message.count", 1 do
        assert_difference "Upload.count", 1 do
          assert_difference "ActionMailer::Base.deliveries.size", 1 do
            normalized_params(@params).each do |p|
              Griddler::Email.new(p).process
            end
          end
        end
      end
    end
  end

  should "not process message without any attachment and not send any notifications" do
    assert_difference "User.count", 0 do
      assert_difference "Message.count", 0 do
        assert_difference "Upload.count", 0 do
          assert_difference "ActionMailer::Base.deliveries.size", 0 do
            normalized_params({
              "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Forgot attachments",
              "text" => "Umm, I must have forgotten something!?"
            }).each do |p|
              Griddler::Email.new(p).process
            end
          end
        end
      end
    end
  end

  should "ignore text attachments and upload audio files and send valid message notification" do
    attachment1 = ActionDispatch::Http::UploadedFile.new({
      :filename     => "sample.m4a",
      :content_type => "invalid/content-type",
      :tempfile     => File.new("#{Rails.root}/test/fixtures/sample.m4a")
    })
    # attachment1.content_type = "audio/x-m4a"  # re-assign, doesn't work otherwise!

    attachment2 = ActionDispatch::Http::UploadedFile.new({
      :filename     => "msg-1483-73.txt",
      :content_type => "text/plain",
      :tempfile     => File.new("#{Rails.root}/test/fixtures/msg-1483-73.txt")
    })
    # attachment2.content_type = "text/plain"  # re-assign, doesn't work otherwise!

    assert_difference "User.count", 1 do
      assert_difference "Message.count", 1 do
        assert_difference "Upload.count", 1 do
          assert_difference "ActionMailer::Base.deliveries.size", 2 do
            normalized_params({"format" => "xml", "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Wrong content type",
              "html" => "<i>Double check audio file!</i>", "attachments" => "2",
              "attachment1" => attachment1, "attachment2" => attachment2
            }).each do |p|
              Griddler::Email.new(p).process
            end
          end
        end
      end
    end
    assert_equal "We are working hard transcribing your message.", ActionMailer::Base.deliveries[1].subject
  end

  should "not process with invalid audio file and send invalid message notification" do
    attachement1 = ActionDispatch::Http::UploadedFile.new({
      :filename     => "sample.m4a",
      :content_type => "invalid/content-type",
      :tempfile     => File.new("#{Rails.root}/test/fixtures/msg-1483-73.txt")
    })

    assert_difference "User.count", 0 do
      assert_difference "Message.count", 1 do
        assert_difference "Upload.count", 0 do
          assert_difference "ActionMailer::Base.deliveries.size", 0 do
            normalized_params({
              "format" => "xml", "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Wrong content type",
              "html" => "<i>Double check audio file!</i>", "attachments" => "1", "attachment1" => attachement1
            }).each do |p|
              Griddler::Email.new(p).process
            end
          end
        end
      end
    end
  end

  protected

  def normalized_params(params)
    params = ActionController::Parameters.new(params)
    Array.wrap(Griddler.configuration.email_service.normalize_params(params))
  end

end