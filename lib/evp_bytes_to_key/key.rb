require 'digest/md5'

module EvpBytesToKey
  # This class is used to generate a new encryption key (and iv, if applicable) from a password in a way that
  # is compatible with how the openssl command line utility generates keys and ivs. It emulates the logic of
  # EVP_KeyToBytes from OpenSSL but is not a direct drop-in replacement because it does not support options
  # like the number of rounds to use or the message digest algorithm to use.
  class Key
    # @return [String] the key or iv value in the named format
    attr_accessor :key, :key_hex, :iv, :iv_hex
    private :key=, :key_hex=, :iv=, :iv_hex=

    # Generate a key from a given password. This key is identical to the key generated
    # by EVP_KeyToBytes() in the openssl command-line utility.
    #
    # @param password [String] the password used for key generation
    # @param salt [String, nil] the salt used for key generation
    # @param bits [Integer] the bit length of the key, must be divisible by 8
    # @param iv_length [Integer] the byte length of the IV
    #
    # @return [EvpBytesToKey::Key]
    def initialize(password=nil, salt=nil, bits=nil, iv_length=nil)
      validate_arguments!({ :password => password, :salt => salt, :bits => bits, :iv_length => iv_length })

      @password = password
      @salt = salt
      @bits = bits
      @iv_length = iv_length

      generate_key!
    end

    private

    # Validates all the arguments passed to initialize
    #
    # @param args [Hash] The arguments passed to initialize
    # @raise [EvpBytesToKey::ArgumentError]
    def validate_arguments!(args)
      raise EvpBytesToKey::ArgumentError.new('password must be a String') unless args[:password].is_a?(String)

      if args[:salt]
        unless args[:salt].is_a?(String) && args[:salt].bytesize == 8
          raise EvpBytesToKey::ArgumentError.new('salt must be an 8 byte String')
        end
      end

      unless args[:bits].is_a?(Integer) && args[:bits] >= 0 && args[:bits] % 8 == 0
        raise EvpBytesToKey::ArgumentError.new('bits must be a non-negative Integer evenly divisible by 8')
      end

      unless args[:iv_length].is_a?(Integer) && args[:iv_length] >= 0 && args[:iv_length] % 2 == 0
        raise EvpBytesToKey::ArgumentError.new('iv_length must be an even Integer >= 0')
      end
    end

    # Generate a key from the supplied arguments by iteratively hashing the values and adding them
    # to bytes until bytes has been fully populated
    #
    # @return [String] the hexadecimal string representation of the generated key
    def generate_key!
      key_length = @bits / 8
      last_hash = ''
      bytes = ''

      # Each iteration hashes the previous hash + password + salt to get the new hash, which is
      # appended to the list of all hashes until it has enough bytes to constitute both the key
      # and the iv
      loop do
        last_hash = Digest::MD5.digest(last_hash + @password + @salt.to_s)
        bytes = bytes + last_hash

        break if bytes.bytesize >= (key_length) + @iv_length.to_i
      end

      self.key = bytes.byteslice(0..key_length - 1)
      self.iv = bytes.byteslice(key_length..key_length + @iv_length - 1)
      self.key_hex = self.key.unpack('H*').first
      self.iv_hex = self.iv.unpack('H*').first
    end
  end
end
