class DRb::Worm::Master < DRb::Worm::Connection

  def create_ca
    @ca = DRb::Worm::Certificates.new 'master'
    @ca.create_key
    @ca.create_ca_certificate
  end

  def start_service
    create_ca

    super
  end

end

