require 'test_helper'

class Segment::DocumentSegmentTest < ActiveSupport::TestCase
  context "validations" do
    subject { FactoryGirl.create(:document_segment) }

    should validate_presence_of :document
    should validate_presence_of :track
  end
end
