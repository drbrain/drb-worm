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

  def test_create_key
    key = @ca.create_key

    assert_kind_of OpenSSL::PKey::RSA, key
  end

end

