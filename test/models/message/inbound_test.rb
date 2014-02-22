require 'test_helper'

class Message::InboundTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of :from
  end

  should "create" do
    assert_difference "Message::Inbound.count", 1 do
      m = Message::Inbound.create(from: "from@example.com", to: "to@example.com", cc: "cc@example.com", subject: "I like pickles", 
        text: "I really like pickles!", html: "<i>I really like pickles with HTML!</i>")
    end
  end

end
