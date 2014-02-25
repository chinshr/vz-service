require 'test_helper'

class EndpointsControllerTest < ActionController::TestCase
  setup do
    EndpointsController.any_instance.stubs(:upload_file_to_s3_bucket).returns(true)
    ActionMailer::Base.deliveries.clear
    attachment1 = ActionDispatch::Http::UploadedFile.new({
      :filename     => "sample.m4a",
      :content_type => "audio/x-m4a",
      :tempfile     => File.new("#{Rails.root}/test/fixtures/sample.m4a")
    })
    attachment1.content_type = "audio/x-m4a"  # re-assign, doesn't work otherwise!
    
    @params = {"dkim"=>"none", "envelope"=>{"to"=>["my@app.example.com"], "from"=>"raj@example.com"}, 
      "subject"=>"Sample recording 1", 
      "attachment-info"=>"{\"attachment1\":{\"filename\":\"sample.m4a\",\"name\":\"sample.m4a\",\"type\":\"audio/x-m4a\"}}",
      "charsets"=>"{\"to\":\"UTF-8\",\"subject\":\"UTF-8\",\"from\":\"UTF-8\"}",
      "headers"=>"Received: by mx-006.sjc1.sendgrid.net with ...", 
      "to"=>"my@app.example.com", "from"=>"Juergen Fesslmeier <juergen@synctv.com>", "sender_ip"=>"199.36.142.181", 
      "attachment1"=>attachment1, "attachments"=>"1", "html" => "<i>Check this out!</i>"}
  end

  should "process message with attachments, signup user and send notifications" do
    assert_difference "User.count", 1 do
      assert_difference "Message.count", 1 do
        assert_difference "Upload.count", 1 do
          assert_difference "ActionMailer::Base.deliveries.size", 2 do
            post :receive_email, @params.merge({"format" => "xml"})
            assert_response :success
          end
        end
      end
    end
    
    assert_equal "Confirmation instructions", ActionMailer::Base.deliveries[0].subject
    assert_equal "Congrats, we are processing your audio files.", ActionMailer::Base.deliveries[1].subject
    assert_equal User.last, Message.last.sender
    assert_equal User.last, Upload.last.user
  end

  should "not process message without any attachment and not send any notifications" do
    assert_difference "User.count", 0 do
      assert_difference "Message.count", 0 do
        assert_difference "Upload.count", 0 do
          assert_difference "ActionMailer::Base.deliveries.size", 0 do
            post :receive_email, {"format" => "xml", "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Forgot attachments", 
              "text" => "Umm, I must have forgotten something!?"}
            assert_response :unprocessable_entity
          end
        end
      end
    end
  end

  should "not process with invalid audio files and send invalid message notification" do
    attachement1 = ActionDispatch::Http::UploadedFile.new({
      :filename     => "sample.m4a",
      :content_type => "invalid/content-type",
      :tempfile     => File.new("#{Rails.root}/test/fixtures/sample.m4a")
    })

    assert_difference "User.count", 0 do
      assert_difference "Message.count", 1 do
        assert_difference "Upload.count", 0 do
          assert_difference "ActionMailer::Base.deliveries.size", 1 do
            post :receive_email, {"format" => "xml", "from" => "raj@example.com", "to" => "my@voyz.es", "subject" => "Wrong content type", 
              "html" => "<i>Double check audio file!</i>", "attachments" => "1", "attachment1" => attachement1}
            assert_response :unprocessable_entity
          end
        end
      end
    end
    
    assert_equal "Sorry, your message could not be processed.", ActionMailer::Base.deliveries[0].subject
  end
  
end
