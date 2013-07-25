require 'openssl'

class DRb::Worm::Certificates

  attr_reader :ca_cert
  attr_reader :key

  def initialize name, key_size = 4096
    @subject =
      OpenSSL::X509::Name.parse "CN=#{name}/CN=drb-worm/CN=segment7/DC=net"

    @key_size = key_size
  end

  def create_ca_certificate
    @ca_cert = create_certificate @key
    @ca_cert.serial  = 0

    @ca_cert.not_before = Time.now
    @ca_cert.not_after  = Time.utc 2038, 01, 19, 03, 14, 07 # for ruby 1.8

    @ca_cert.issuer     = @subject

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = @ca_cert
    extension_factory.issuer_certificate  = @ca_cert

    @ca_cert.add_extension \
      extension_factory.create_extension 'subjectKeyIdentifier', 'hash'
    @ca_cert.add_extension \
      extension_factory.create_extension 'basicConstraints', 'CA:TRUE', true
    @ca_cert.add_extension \
      extension_factory.create_extension 'keyUsage', 'cRLSign,keyCertSign', true

    @ca_cert.sign @key, OpenSSL::Digest::SHA1.new

    @ca_cert
  end

  def create_certificate key
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2

    cert.public_key = @key.public_key
    cert.subject    = @subject
    cert.public_key = key.public_key

    cert
  end

  def create_certificate_signing_request key
    csr = OpenSSL::X509::Request.new
    csr.version = 0
    csr.subject = @subject
    csr.public_key = key.public_key

    csr.sign key, OpenSSL::Digest::SHA1.new

    csr
  end

  def create_key
    @key = OpenSSL::PKey::RSA.new @key_size
  end

end

