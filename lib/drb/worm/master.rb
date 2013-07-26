##
# Master is the master Connection and includes a Certificate Authority that
# other Connection objects can use to bootstrap themselves into the network.
#
# Since a Connection uses an insecure connection to request a signed
# certificate the SSL is only useful for casual privacy.
#
# Example:
#
#   master = DRb::Worm::Master.new
#   service = master.start_service
#
#   puts "SSL URI: #{service.uri}"
#
#   DRb.start_service nil, master
#
#   puts "Certificate bootstrap URI: #{DRb.uri}"
#
# The first URI is SSL-protected while the second URI can be used by
# Connection to create the required signed certificate.

class DRb::Worm::Master < DRb::Worm::Connection

  ##
  # Creates a Certificates object that is set up as a Certificate Authority.

  def create_ca # :nodoc:
    @ca = DRb::Worm::Certificates.new 'master'
    @ca.create_key
    @ca.create_ca_certificate
  end

  ##
  # Starts a DRb SSL service with no front object for this node and returns
  # the service.
  #
  # You should also start a non-SSL DRb service so clients may bootstrap
  # themselves into the private network:
  #
  #   master = DRb::Worm::Master.new
  #   service = master.start_service
  #   DRb.start_service nil, master

  def start_service
    create_ca

    super
  end

end

