require 'minitest/autorun'
require 'drb/worm'

class TestDRbWormCertificates < Minitest::Test

  def setup
    @ca = DRb::Worm::Certificates.new 'test', 1024
  end

  def test_create_ca_certificate
    key = @ca.create_key

    ca_cert = @ca.create_ca_certificate

    expected = '/CN=test/CN=drb-worm/CN=segment7/DC=net'

    assert_equal expected, ca_cert.issuer.to_s
    assert_equal expected, ca_cert.subject.to_s

    assert ca_cert.verify key
  end

  def test_create_certificate
    key = @ca.create_key

    cert = @ca.create_certificate key

    assert_equal key.public_key.to_text, cert.public_key.to_text

    assert_equal '',                                        cert.issuer.to_s
    assert_equal '/CN=test/CN=drb-worm/CN=segment7/DC=net', cert.subject.to_s
  end

  def test_create_certificate_signing_request
    key = @ca.create_key

    csr = @ca.create_certificate_signing_request key

    assert_equal key.public_key.to_text, csr.public_key.to_text

    assert_equal '/CN=test/CN=drb-worm/CN=segment7/DC=net', csr.subject.to_s

    assert csr.verify key.public_key
  end

  def test_create_key
    key = @ca.create_key

    assert_kind_of OpenSSL::PKey::RSA, key
  end

end

