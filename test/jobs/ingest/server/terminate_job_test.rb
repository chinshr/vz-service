require 'test_helper'

class Ingest::Server::TerminateJobTest < ActiveSupport::TestCase

  should "terminate instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    Ingest::Server.any_instance.expects(:_terminate).returns(true)
    Ingest::Server::TerminateJob.new.perform(server.id)
  end

  should "not terminate instance with busy workers" do
    server = FactoryGirl.create(:cpw_ingest_server)
    worker = FactoryGirl.create(:ingest_worker, server: server)
    Ingest::Server.any_instance.expects(:_terminate).never
    Ingest::Server::TerminateJob.new.perform(server.id)
  end

  should "terminate instance without busy workers" do
    server = FactoryGirl.create(:cpw_ingest_server)
    worker1 = FactoryGirl.create(:ingest_worker, server: server, aasm_state: "stopped")
    worker2 = FactoryGirl.create(:ingest_worker, server: server, aasm_state: "finished")
    Ingest::Server.any_instance.expects(:_terminate).returns(true)
    Ingest::Server::TerminateJob.new.perform(server.id)
  end

end