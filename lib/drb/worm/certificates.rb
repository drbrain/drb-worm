require 'openssl'

##
# Certificates handles Certificate Authority (CA) and Certificate Signing
# Request (CSR) duties.  Certificates may be used in either mode depending
# upon which messages are sent to it.
#
# For either mode, create_key must be called before setting up a CA or
# creating a CSR.
#
# CA mode:
#
#   ca = DRb::Worm::Certificates.new 'example'
#   ca.create_key
#   ca.create_ca_certificate
#
# CSR mode:
#
#   child = DRb::Worm::Certificates.new 'child'
#   child.create_key
#   csr = child.create_certificate_signing_request
#
#   # ca is a CA mode Certificates instance as created above
#   cert_pem = ca.create_child_certificate csr
#   cert = OpenSSL::X509::Certificate.new cert_pem

class DRb::Worm::Certificates

  ##
  # The default key size for RSA keys

  KEY_SIZE = 4096

  ##
  # The CA certificate.  This is set after create_ca_certificate is sent.

  attr_reader :ca_cert

  ##
  # The RSA keypair.  This is set after create_key is sent.

  attr_reader :key

  ##
  # Creates a new Certificates object appending +name+ to the pre-configured
  # namespace of CN=drb-worm/CN=segment7/DC=net.  The +key_size+ sets the RSA
  # key size.

  def initialize name, key_size = KEY_SIZE
    @subject =
      OpenSSL::X509::Name.parse "CN=#{name}/CN=drb-worm/CN=segment7/DC=net"

    @key_size = key_size

    @serial = 0

    @ca_cert           = nil
    @certificate_store = nil
    @key               = nil
  end

  ##
  # Creates a CA certificate for use by create_child_certificate

  def create_ca_certificate
    @serial = 0

    @ca_cert = create_certificate @key

    @ca_cert.serial = @serial
    @ca_cert.issuer = @subject

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

  ##
  # Creates a X509 Certificate with an expiry time in 2038 (for ruby 1.8
  # compatibility), the subject from the name created in #initialize and
  # public key from +key+ filled in.

  def create_certificate key # :nodoc:
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2

    cert.not_before = Time.now
    cert.not_after  = Time.utc 2038, 01, 19, 03, 14, 07 # for ruby 1.8
    cert.subject    = @subject
    cert.public_key = key.public_key

    cert
  end

  ##
  # Creates a certificate signing request.  Returns the CSR in PEM format (as
  # a String).

  def create_certificate_signing_request
    csr = OpenSSL::X509::Request.new
    csr.version = 0
    csr.subject = @subject
    csr.public_key = @key.public_key

    csr.sign key, OpenSSL::Digest::SHA1.new

    csr.to_pem
  end

  ##
  # Creates a child certificate which is signed by the CA certificate for
  # the CSR in PEM format, +csr_pem+.  Returns the signed certificate in PEM
  # format (as a String).

  def create_child_certificate csr_pem
    csr = OpenSSL::X509::Request.new csr_pem

    cert = create_certificate csr.public_key

    cert.serial  = @serial += 1
    cert.issuer  = @subject
    cert.subject = csr.subject

    extension_factory = OpenSSL::X509::ExtensionFactory.new
    extension_factory.subject_certificate = cert
    extension_factory.issuer_certificate  = @ca_cert

    cert.add_extension \
      extension_factory.create_extension 'subjectKeyIdentifier', 'hash'
    cert.add_extension \
      extension_factory.create_extension 'basicConstraints', 'CA:FALSE', true
    cert.add_extension \
      extension_factory.create_extension('keyUsage',
                                         'keyEncipherment,dataEncipherment,digitalSignature')

    cert.sign @key, OpenSSL::Digest::SHA1.new

    cert.to_pem
  end

  ##
  # Creates an RSA keypair

  def create_key
    @key = OpenSSL::PKey::RSA.new @key_size
  end

end

