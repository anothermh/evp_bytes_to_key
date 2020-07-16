require 'digest/md5'

module EvpBytesToKey
  # This class is used to generate a new encryption key from a password in a way that is compatible with
  # EVP_KeyToBytes() from OpenSSL.
  class Key
    # Generate a key from a given password. This key is the identical to the key generated
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

    # @return [Array<nil, String>] n elements that are either nil or a 16-byte String
    def bytes_array
      @bytes_array ||= Array.new(@bits / 8 / 16)
    end

    # @return [String] the key that was generated as a hexadecimal string
    def hex
      @hex ||= bytes.unpack('H*').first
    end

    # @return [String] the key that was generated as a string of bytes
    def bytes
      @bytes ||= bytes_array.join('')
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

      unless args[:iv_length].is_a?(Integer) && args[:iv_length] >= 0
        raise EvpBytesToKey::ArgumentError.new('iv_length must be a non-negative Integer')
      end
    end

    # Generate a key from the supplied arguments by iteratively calling add_hash_to_bytes_array
    # until bytes_array has been fully populated
    #
    # @return [String] the hexadecimal string representation of the generated key
    def generate_key!
      loop do
        break if bytes_array_fully_populated?
        add_hash_to_bytes_array
      end

      hex
    end

    # bytes_array is populated from the first element to the last; if the last element is nil
    # then bytes_array has not been fully populated
    #
    # @return [Boolean] true if the last element is not nil
    def bytes_array_fully_populated?
      !bytes_array.last.nil?
    end

    # Finds the next occurrence of nil in bytes_array and sets it to a newly generated MD5 hash
    #
    # @return [String] the byte string value stored in bytes_array[next_nil_index]
    def add_hash_to_bytes_array
      bytes_array[next_nil_index] = generate_hash
    end

    # @return [Integer] the index of the first nil element in the bytes array
    def next_nil_index
      bytes_array.find_index(&:nil?)
    end

    # Generate a new MD5 hash of a given string. The string used depends on what iteration this is.
    # If this is the first iteration then @password is hashed. If this is not the first iteration then
    # the previous iteration's hash and @password are hashed together.
    #
    # @return [String] a 16-byte MD5 sum as a string of bytes
    def generate_hash
      Digest::MD5.digest(bytes_array[next_nil_index - 1].to_s + @password)
    end
  end
end
