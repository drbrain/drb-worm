class DRb::Worm::Connection

  attr_accessor :ca

  attr_reader :certificate

  attr_reader :key

  attr_reader :name

  def initialize
    @name = "#{Socket.gethostname}-#{$PID}"

    @ca          = nil
    @certificate = nil
    @key         = nil
  end

  def certificate_store
    @certificate_store ||=
      begin
        # use local certificate
        certificate = OpenSSL::X509::Certificate.new @ca.ca_cert.to_pem

        store = OpenSSL::X509::Store.new
        store.add_cert certificate
        store
      end
  end

  def create_certificate
    child = DRb::Worm::Certificates.new @name

    @key     = child.create_key
    csr_pem  = child.create_certificate_signing_request @key
    cert_pem = @ca.create_child_certificate csr_pem

    @certificate = OpenSSL::X509::Certificate.new cert_pem
  end

  def ssl_config
    {
      SSLCertificate:        @certificate,
      SSLPrivateKey:         @key,
      SSLCaCertificateStore: certificate_store,
      SSLVerifyMode:
        OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT,
    }
  end

  def start_service
    create_certificate

    DRb.start_service 'drbssl://localhost:0', nil, ssl_config
  end

end

