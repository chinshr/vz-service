require 'test_helper'

class IngestTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to :upload
    should belong_to :ingestable
  end

  context "validations" do
    should validate_presence_of :upload
    should validate_presence_of :ingestable
  end
  
end
