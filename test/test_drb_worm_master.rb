require 'minitest/autorun'
require 'drb/worm'

class TestDRbWormMaster < Minitest::Test

  def setup
    @c = DRb::Worm::Master.new
  end

  def test_create_ca
    @c.create_ca

    ca_cert = @c.ca.ca_cert

    assert_kind_of OpenSSL::X509::Certificate, ca_cert

    assert_equal ca_cert.issuer, ca_cert.subject
  end

  def test_start_service
    s = @c.start_service

    assert_match %r%^drbssl://%, s.uri

    assert_kind_of OpenSSL::X509::Certificate, @c.ca.ca_cert
  end

end

