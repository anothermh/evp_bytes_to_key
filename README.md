# EvpBytesToKey

This gem is a pure Ruby implementation of OpenSSL's `EVP_BytesToKey()` function. This function is used by the command-line `openssl` utility to generate a key from a password. It is not available as a method in the `OpenSSL` Ruby module.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'evp_bytes_to_key'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install evp_bytes_to_key

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
salt = nil

# must be a positive integer divisible by 8
bits = 128

# must be an integer >= 0
iv_length = 0
```

Then use the `Key` class to get access to the key:

```ruby
key = EvpBytesToKey::Key.new(password, salt, bits, iv_length)
=> #<EvpBytesToKey::Key:0x00007fd4c3a461c8
 @bits=128,
 @bytes="_M\xCC;Z\xA7e\xD6\x1D\x83'\xDE\xB8\x82\xCF\x99",
 @bytes_array=["_M\xCC;Z\xA7e\xD6\x1D\x83'\xDE\xB8\x82\xCF\x99"],
 @hex="5f4dcc3b5aa765d61d8327deb882cf99",
 @iv_length=0,
 @password="password",
 @salt=nil>

key.hex
=> "5f4dcc3b5aa765d61d8327deb882cf99"

key.bytes
=> "_M\xCC;Z\xA7e\xD6\x1D\x83'\xDE\xB8\x82\xCF\x99"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anothermh/evp_bytes_to_key.
