require 'test_helper'

class Mailer::HelperTest < ActiveSupport::TestCase

  should "#prettify" do
    assert_equal "John <john@example.com>", Mailer::Helper.prettify("John", "john@example.com")
  end

  should "#unprettify" do
    assert_equal "john@example.com", Mailer::Helper.unprettify("John <john@example.com>")
  end

  should "#unprettify_multiples" do
    assert_equal ["john@example.com", "sam@example.com"],
      Mailer::Helper.unprettify_multiples("John <john@example.com>, Sam <sam@example.com>")
  end

  should "parse locale from email addresses" do
    assert_equal "en", Mailer::Helper.locale_from_email_address("my+en@voyz.es")
    assert_equal "en-US", Mailer::Helper.locale_from_email_address("my+en_US@voyz.es")
    assert_equal "es", Mailer::Helper.locale_from_email_address("my+es@voyz.es")
    assert_equal nil, Mailer::Helper.locale_from_email_address("my@voyz.es")
    assert_equal nil, Mailer::Helper.locale_from_email_address("")
    assert_equal nil, Mailer::Helper.locale_from_email_address(nil)
  end

end