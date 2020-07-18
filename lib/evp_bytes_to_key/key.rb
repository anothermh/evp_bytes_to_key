# frozen_string_literal: true

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
    def initialize(password = nil, salt = nil, bits = nil, iv_length = nil)
      @password = validate_password(password)
      @salt = validate_salt(salt)
      @bits = validate_bits(bits)
      @iv_length = validate_iv_length(iv_length)

      generate_key!
    end

    private

    # @param password [String] the password that should be used for key derivation
    # @raise [EvpBytesToKey::ArgumentError]
    # @return [String]
    def validate_password(password)
      raise EvpBytesToKey::ArgumentError, 'password must be a String' unless password.is_a?(String)

      password
    end

    # @param salt [String] the salt to append to the password that should be used for key derivation
    # @raise [EvpBytesToKey::ArgumentError]
    # @return [String, nil]
    def validate_salt(salt)
      if salt
        raise EvpBytesToKey::ArgumentError, 'salt must be an 8 byte String' unless salt.is_a?(String) && salt.bytesize == 8
      end

      salt
    end

    # @param bits [Integer] the size of the key that should be returned in bits
    # @raise [EvpBytesToKey::ArgumentError]
    # @return [Integer]
    def validate_bits(bits)
      unless bits.is_a?(Integer) && bits >= 0 && (bits % 8).zero?
        raise EvpBytesToKey::ArgumentError, 'bits must be a non-negative Integer evenly divisible by 8'
      end

      bits
    end

    # @param iv_length [Integer] the size of the iv that should be returned in bytes
    # @raise [EvpBytesToKey::ArgumentError]
    # @return [Integer]
    def validate_iv_length(iv_length)
      unless iv_length.is_a?(Integer) && iv_length >= 0 && (iv_length % 2).zero?
        raise EvpBytesToKey::ArgumentError, 'iv_length must be an even Integer >= 0'
      end

      iv_length
    end

    # Generate a key from the supplied arguments by iteratively hashing the values and adding them
    # to bytes until bytes has been fully populated
    #
    # @return [void]
    def generate_key!
      key_length = @bits / 8
      last_hash = ''
      bytes = ''

      # Each iteration hashes the previous hash + password + salt to get the new hash, which is
      # appended to the list of all hashes until it has enough bytes to constitute both the key
      # and the iv
      loop do
        last_hash = Digest::MD5.digest(last_hash + @password + @salt.to_s)
        bytes += last_hash

        break if bytes.bytesize >= key_length + @iv_length.to_i
      end

      set_key_and_iv(bytes, key_length)
    end

    # @param bytes [String] the byte string from which the key and iv are extracted
    # @param key_length [Integer] the length of the key in bytes
    # @return [void]
    def set_key_and_iv(bytes, key_length)
      self.key = bytes.byteslice(0..key_length - 1)
      # rubocop:disable Style/UnpackFirst
      self.key_hex = key.unpack('H*').first
      # rubocop:enable Style/UnpackFirst

      return unless bytes.bytesize > key_length

      self.iv = bytes.byteslice(key_length..key_length + @iv_length - 1)
      # rubocop:disable Style/UnpackFirst
      self.iv_hex = iv.unpack('H*').first
      # rubocop:enable Style/UnpackFirst
    end
  end
end
