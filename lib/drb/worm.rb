require 'drb'
require 'drb/ssl'

class DRb::Worm

  VERSION = '1.0'

end

require 'drb/worm/certificates'
require 'drb/worm/connection'
require 'drb/worm/master'

