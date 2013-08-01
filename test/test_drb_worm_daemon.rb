require 'minitest/autorun'
require 'drb/worm'

class TestDRbWormDaemon < Minitest::Test

  def teardown
    servers = DRb.instance_variable_get :@server

    servers.values.each do |server|
      server.stop_service
    end

    DRb.primary_server = nil
  end

  def test_connect_to_master
    master = DRb::Worm::Master.new
    ssl_master = master.start_service

    master = DRb.start_service nil, master

    parent = DRb.start_service

    d = DRb::Worm::Daemon.new parent.uri, master.uri

    ssl_child = d.connect_to_master

    assert ssl_child.config[:SSLCertificate]
  end

  def test_die
    assert_raises SystemExit do
      DRb::Worm::Daemon.new(nil).die
    end
  end

  def test_watch_parent
    front = Object.new

    begin
      $VERBOSE = nil
      def front.object_id() raise DRb::DRbConnError end
    ensure
      $VERBOSE = true
    end

    DRb.start_service nil, front

    drb_thread = DRb.thread

    d = DRb::Worm::Daemon.new DRb.uri

    thread = d.watch_parent

    thread.join

    refute thread.alive?
    refute drb_thread.alive?
  end

end

