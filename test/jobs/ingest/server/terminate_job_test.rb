require 'test_helper'

class Ingest::Server::TerminateJobTest < ActiveSupport::TestCase

  should "terminate instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    Ingest::Server.any_instance.expects(:_terminate).returns(true)
    Ingest::Server::TerminateJob.new.perform(server.id)
  end

  should "not terminate instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    server.ingests << FactoryGirl.create(:ingest_audio)
    Ingest::Server.any_instance.expects(:_terminate).never
    Ingest::Server::TerminateJob.new.perform(server.id)
  end

end