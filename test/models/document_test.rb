require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  context "associations" do
    should have_many :ingests
  end
  
  context "validations" do
    should validate_presence_of :title
    should ensure_length_of(:title).is_at_most(255)
  end
end
