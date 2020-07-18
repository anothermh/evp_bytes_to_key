# EvpBytesToKey

This gem is a pure Ruby implementation of OpenSSL's
[`EVP_BytesToKey()`](https://www.openssl.org/docs/man1.0.2/man3/EVP_BytesToKey.html) function as it is used by
the `openssl` command line utility. This function is used to generate a key and IV from a given password. (and
optional salt)

The purpose of this gem is to make it easier to encrypt or decrypt data that has been encrypted by `openssl`
with a password on the command line by replicating the logic used to derive a key and IV from a given password.

The [OpenSSL documentation](https://www.openssl.org/docs/man1.0.2/man3/EVP_BytesToKey.html) states:

> Newer applications should use a more modern algorithm such as PBKDF2

Therefore use of this key derivation function is at your own risk. It is provided here to make interoperation
with Ruby more convenient.

The is **not** a drop-in replacement for `EVP_BytesToKey()`. The [original
function](https://github.com/openssl/openssl/blob/2e9d61ecd81a6a512a0700486ccc1b3784b4c969/crypto/evp/evp_key.c#L78-L154)
supports specifying an algorithm (to determine key length and IV and IV length automatically), a message digest
(so a digest other than MD5 can be used), and the number of rounds.

This **is** a drop-in replacement for `EVP_BytesToKey()` as it is used by the `openssl` command line utility,
that is, using MD5 with 1 round. However, the options passed to this method require some knowledge of the algorithm
in use, e.g., `aes256` will use a 256-bit key and a 16-byte IV while `rc4-40` will use a 40-bit key
and no IV. These are provided as arguments to `EvpBytesToKey::Key.new`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'evp_bytes_to_key'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install evp_bytes_to_key

## Requirements

This gem requires Ruby 2.0.0 due to the format of its `gemspec` file but the `EvpBytesToKey` module has been tested to work in Ruby as low as 1.9.3.

## Usage

Require the gem first:

```ruby
require 'evp_bytes_to_key'
```

Set the arguments for key generation. All arguments are required.

```ruby
# must be a string and may be empty
password = 'password'

# must be nil or an eight-byte string
salt = 'saltsalt'

# must be a positive integer divisible by 8
bits = 256

# must be an integer >= 0
iv_length = 16
```

Then use the `Key` class to get access to the key:

```ruby
key = EvpBytesToKey::Key.new(password, salt, bits, iv_length)
=> #<EvpBytesToKey::Key:0x00007fe388095330
 @bits=256,
 @iv="\v\\\xA7\xB1\b\x1F\x94\xB1\xAC\x12\xE3\xC8\xBA\x87\xD0Z",
 @iv_hex="0b5ca7b1081f94b1ac12e3c8ba87d05a",
 @iv_length=16,
 @key="\xFD\xBD\xF3A\x9F\xFF\x98\xBD\xB0$\x13\x90\xF6*\x9D\xB3_J\xBA)\xD7uf7y\x971N\xBF\xC7\t\xF2",
 @key_hex="fdbdf3419fff98bdb0241390f62a9db35f4aba29d77566377997314ebfc709f2",
 @password="password",
 @salt="saltsalt">

key.key_hex
=> "fdbdf3419fff98bdb0241390f62a9db35f4aba29d77566377997314ebfc709f2"

key.iv_hex
=> "0b5ca7b1081f94b1ac12e3c8ba87d05a"

key.key
=> "\xFD\xBD\xF3A\x9F\xFF\x98\xBD\xB0$\x13\x90\xF6*\x9D\xB3_J\xBA)\xD7uf7y\x971N\xBF\xC7\t\xF2"

key.iv
=> "\v\\\xA7\xB1\b\x1F\x94\xB1\xAC\x12\xE3\xC8\xBA\x87\xD0Z"
```

These values can be compared to the values returned by the command line utility `openssl`:

```bash
echo -n "foo" | openssl enc -e -base64 -aes256 -S 73616c7473616c74 -pass pass:password -p

salt=73616C7473616C74
key=FDBDF3419FFF98BDB0241390F62A9DB35F4ABA29D77566377997314EBFC709F2
iv =0B5CA7B1081F94B1AC12E3C8BA87D05A
U2FsdGVkX19zYWx0c2FsdOnid6UWvFAXeeXIe+sL0l8=
```

Note that `openssl` requires the salt in hexadecimal format:

```bash
printf saltsalt | xxd
00000000: 7361 6c74 7361 6c74                      saltsalt
```

### Examples

#### `aes256` with a salt and IV

Encrypt with `openssl`:

```bash
echo -n "foo" | openssl enc -e -base64 -aes256 -S 73616c7473616c74 -pass pass:password
```

This returns:

    U2FsdGVkX19zYWx0c2FsdOnid6UWvFAXeeXIe+sL0l8=

Decrypt with Ruby:

```ruby
require 'openssl'
require 'base64'
require 'evp_bytes_to_key'

key = EvpBytesToKey::Key.new('password', 'saltsalt', 256, 16)
decipher = OpenSSL::Cipher.new('aes256')
decipher.decrypt
decipher.key = key.key
decipher.iv = key.iv
ciphertext = Base64.strict_decode64('U2FsdGVkX19zYWx0c2FsdOnid6UWvFAXeeXIe+sL0l8=')
ciphertext = ciphertext.byteslice(16..-1) if ciphertext.byteslice(0, 8) == 'Salted__'
plaintext = decipher.update(ciphertext) + decipher.final
```

This returns:

    "foo"

Encrypt with Ruby:

```
require 'openssl'
require 'base64'
require 'evp_bytes_to_key'

salt = 'saltsalt'
key = EvpBytesToKey::Key.new('password', salt, 256, 16)
cipher = OpenSSL::Cipher.new('aes256')
cipher.encrypt
cipher.key = key.key
cipher.iv = key.iv
ciphertext = cipher.update('foo') + cipher.final
ciphertext = "Salted__#{salt}#{ciphertext}" if salt
ciphertext = Base64.strict_encode64(ciphertext)
```

This returns:

    "U2FsdGVkX19zYWx0c2FsdOnid6UWvFAXeeXIe+sL0l8="

Decrypt with `openssl`:

```bash
echo -n "U2FsdGVkX19zYWx0c2FsdOnid6UWvFAXeeXIe+sL0l8=" | base64 --decode | openssl enc -d -aes256 -S 73616c7473616c74 -pass pass:password
```

This returns:

    foo

#### `rc4` with no salt and no IV

Encrypt with `openssl`:

```bash
echo -n "foo" | openssl enc -e -base64 -rc4 -nosalt -pass pass:password
```

This returns:

    jpdE

Decrypt with Ruby:

```ruby
require 'openssl'
require 'base64'
require 'evp_bytes_to_key'

key = EvpBytesToKey::Key.new('password', nil, 128, 0)
decipher = OpenSSL::Cipher.new('rc4')
decipher.decrypt
decipher.key = key.key
ciphertext = Base64.strict_decode64('jpdE')
plaintext = decipher.update(ciphertext) + decipher.final
```

This returns:

    "foo"

Encrypt with Ruby:

```
require 'openssl'
require 'base64'
require 'evp_bytes_to_key'

key = EvpBytesToKey::Key.new('password', nil, 128, 0)
cipher = OpenSSL::Cipher.new('rc4')
cipher.encrypt
cipher.key = key.key
ciphertext = cipher.update('foo') + cipher.final
ciphertext = Base64.strict_encode64(ciphertext)
```

This returns:

    "jpdE"

Decrypt with `openssl`:

```bash
echo -n "jpdE" | base64 --decode | openssl enc -d -rc4 -nosalt -pass pass:password
```

This returns:

    foo

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anothermh/evp_bytes_to_key.
