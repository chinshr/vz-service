require 'test_helper'

class Ingest::Server::TerminateJobTest < ActiveSupport::TestCase

  should "terminate instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    Ingest::Server.any_instance.expects(:_terminate).returns(true)
    Ingest::Server::TerminateJob.new.perform(server.id)
  end

end