require 'minitest/autorun'
require 'drb/worm'

class TestDRbWormCertificates < Minitest::Test

  def setup
    @c = DRb::Worm::Certificates.new 'test', 1024
  end

  def test_create_ca_certificate
    key = @c.create_key

    ca_cert = @c.create_ca_certificate

    expected = '/CN=test/CN=drb-worm/CN=segment7/DC=net'

    assert_equal expected, ca_cert.issuer.to_s
    assert_equal expected, ca_cert.subject.to_s

    assert ca_cert.verify key
  end

  def test_create_certificate
    key = @c.create_key

    cert = @c.create_certificate key

    assert_equal key.public_key.to_text, cert.public_key.to_text

    assert_equal '',                                        cert.issuer.to_s
    assert_equal '/CN=test/CN=drb-worm/CN=segment7/DC=net', cert.subject.to_s
  end

  def test_create_certificate_signing_request
    key = @c.create_key

    csr_pem = @c.create_certificate_signing_request key

    csr = OpenSSL::X509::Request.new csr_pem

    assert_equal key.public_key.to_text, csr.public_key.to_text

    assert_equal '/CN=test/CN=drb-worm/CN=segment7/DC=net', csr.subject.to_s

    assert csr.verify key.public_key
  end

  def test_create_child_certificate
    child     = DRb::Worm::Certificates.new 'child', 1024
    child_key = child.create_key
    csr       = child.create_certificate_signing_request child_key

    ca_key = @c.create_key
    @c.create_ca_certificate

    cert_pem = @c.create_child_certificate csr

    assert_kind_of String, cert_pem

    cert = OpenSSL::X509::Certificate.new cert_pem

    assert_equal '/CN=test/CN=drb-worm/CN=segment7/DC=net',  cert.issuer.to_s
    assert_equal '/CN=child/CN=drb-worm/CN=segment7/DC=net', cert.subject.to_s

    assert_equal 1, cert.serial

    assert cert.verify ca_key.public_key
  end

  def test_create_key
    key = @c.create_key

    assert_kind_of OpenSSL::PKey::RSA, key
  end

end

