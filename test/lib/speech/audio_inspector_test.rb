require 'test_helper'

class Speech::AudioInspectorTest < ActiveSupport::TestCase
  
  should "add duration" do
    a = Speech::AudioInspector::Duration.new("00:00:12.12")
    b = Speech::AudioInspector::Duration.new("00:00:02.00")

    assert_equal "00:00:14.12", (a + b).to_s

    a = Speech::AudioInspector::Duration.new("00:10:12.12")
    b = Speech::AudioInspector::Duration.new("08:00:02.00")

    assert_equal "08:10:14.12", (a + b).to_s

    a = Speech::AudioInspector::Duration.new("02:10:12.12")
    b = Speech::AudioInspector::Duration.new("08:55:02.10")

    assert_equal "11:05:14.22", (a + b).to_s

    a = Speech::AudioInspector::Duration.new("00:00:12.12")
    b = Speech::AudioInspector::Duration.new("00:00:02.00")

    a = a + b
    assert_equal "00:00:14.12", a.to_s

    a = a + b

    assert_equal "00:00:16.12", a.to_s

    a = a + b
    assert_equal "00:00:18.12", a.to_s
  end
  
end
