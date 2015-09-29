require 'test_helper'

class Ingest::Server::RestartJobTest < ActiveSupport::TestCase

  should "start instance" do
    server = FactoryGirl.create(:cpw_ingest_server)
    Ingest::Server.any_instance.expects(:_restart).returns(true)
    Ingest::Server::RestartJob.new.perform(server.id)
  end

end