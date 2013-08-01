##
# Connection bootstraps the SSL certificates for the connections between the
# nodes in the worm.  Anyone knowing an address of one of the nodes can
# bootstrap themselves into the network.  SSL is used only for casual privacy
# and provides no security.
#
# Example:
#
#   # master is an instance of DRb::Worm::Master, a Connection subclass
#   master = DRb::DRbObject.new_with_uri "druby://master.example:port"
#
#   c = DRb::Worm::Connection.new
#   c.ca = master.ca
#
#   s = c.start_service
#   puts s.uri

class DRb::Worm::Connection

  ##
  # A Certificates object configured to be the Certificate Authority for a
  # network of nodes.  This can be a DRb reference.

  attr_accessor :ca

  ##
  # This connection's local certificate.  It will be created through
  # start_service.

  attr_reader :certificate

  ##
  # This connection's local RSA keypair.  It will be created through
  # start_service.

  attr_reader :key

  ##
  # Sets the key size for RSA keypairs.

  attr_accessor :key_size

  ##
  # The name for this node's certificate.

  attr_reader :name

  def initialize # :nodoc:
    @name = "#{Socket.gethostname}-#{$PID}"

    @ca          = nil
    @certificate = nil
    @key         = nil
    @key_size    = DRb::Worm::Certificates::KEY_SIZE
  end

  ##
  # The OpenSSL::X509::Store containing the network's CA certificate.

  def certificate_store # :nodoc:
    @certificate_store ||=
      begin
        # use local certificate
        certificate = OpenSSL::X509::Certificate.new @ca.ca_cert.to_pem

        store = OpenSSL::X509::Store.new
        store.add_cert certificate
        store
      end
  end

  ##
  # Creates a new keypair and certificate for this node.  You must set #ca
  # before creating the certificate.

  def create_certificate # :nodoc:
    child = DRb::Worm::Certificates.new @name, @key_size

    @key     = child.create_key
    csr_pem  = child.create_certificate_signing_request
    cert_pem = @ca.create_child_certificate csr_pem

    @certificate = OpenSSL::X509::Certificate.new cert_pem
  end

  ##
  # The DRb SSL configuration for this node.

  def ssl_config # :nodoc:
    {
      SSLCertificate:        @certificate,
      SSLPrivateKey:         @key,
      SSLCaCertificateStore: certificate_store,
      SSLVerifyMode:
        OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT,
    }
  end

  ##
  # Starts a DRb SSL service with no front object for this node and returns
  # the service.
  #
  # You must set the #ca for this connection before starting the service.

  def start_service
    create_certificate

    DRb.start_service 'drbssl://:0', nil, ssl_config
  end

end

