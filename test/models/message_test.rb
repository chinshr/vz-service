require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  context "validations" do
    should validate_presence_of :from
  end
  
  should "create" do
    assert_difference "Message.count", 1 do
      m = Message.create(from: "from@example.com", to: "to@example.com", text: "I like pickles", html: "<i>I like pickles</i>")
    end
  end
end
