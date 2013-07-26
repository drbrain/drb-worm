require 'minitest/autorun'
require 'drb/worm'

class TestDRbWormConnection < Minitest::Test

  def setup
    @c = DRb::Worm::Connection.new
  end

  def test_certificate_store
    ca = create_ca

    child = DRb::Worm::Certificates.new 'test', 1024
    child.create_key
    csr = child.create_certificate_signing_request

    cert_pem = ca.create_child_certificate csr

    cert = OpenSSL::X509::Certificate.new cert_pem

    cert_store = @c.certificate_store

    assert cert_store.verify cert
  end

  def test_create_certificate
    create_ca

    cert = @c.create_certificate

    assert @c.certificate_store.verify cert
  end

  def test_ssl_config
    create_ca

    ssl_config = @c.ssl_config

    assert_equal @c.certificate_store, ssl_config[:SSLCaCertificateStore]
    assert_equal @c.certificate,       ssl_config[:SSLCertificate]
    assert_equal @c.key,               ssl_config[:SSLPrivateKey]

    expected =
      OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT

    assert_equal expected,             ssl_config[:SSLVerifyMode]
  end

  def test_start_service
    @c.ca = create_ca

    s = @c.start_service

    assert_match %r%^drbssl://%, s.uri

    config = s.config

    assert config[:SSLCertificate]
    assert config[:SSLPrivateKey]
    assert config[:SSLCaCertificateStore]
    assert config[:SSLVerifyMode]
  end

  def create_ca
    ca = DRb::Worm::Certificates.new 'test', 1024
    ca.create_key
    ca.create_ca_certificate

    @c.ca = ca
  end

end

