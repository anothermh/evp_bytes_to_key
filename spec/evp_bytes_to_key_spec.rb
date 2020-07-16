# frozen_string_literal: true

RSpec.describe EvpBytesToKey do
  describe EvpBytesToKey::Key do
    it 'validates the password argument' do
      expect { EvpBytesToKey::Key.new }.to raise_error(EvpBytesToKey::ArgumentError).with_message(/password/)
    end

    it 'validates the salt argument' do
      expect { EvpBytesToKey::Key.new('password', 'foo') }.to raise_error(EvpBytesToKey::ArgumentError).with_message(/salt/)
      expect { EvpBytesToKey::Key.new('password', '12345678') }.to raise_error(EvpBytesToKey::ArgumentError).with_message(/bits/)
    end

    it 'validates the bits argument' do
      expect { EvpBytesToKey::Key.new('password', nil, 5) }.to raise_error(EvpBytesToKey::ArgumentError).with_message(/bits/)
      expect { EvpBytesToKey::Key.new('password', nil, 128) }.to raise_error(EvpBytesToKey::ArgumentError).with_message(/iv_length/)
    end

    it 'validates the iv_length argument' do
      expect { EvpBytesToKey::Key.new('password', nil, 128) }.to raise_error(EvpBytesToKey::ArgumentError).with_message(/iv_length/)
    end

    context 'with valid arguments' do
      context 'with a 128 bit key' do
        let(:key) { EvpBytesToKey::Key.new('password', nil, 128, 0) }

        it 'generates a key from a password' do
          expect(key).to be_kind_of(EvpBytesToKey::Key)
        end

        it 'generates a valid hexadecimal value' do
          expect(key.hex).to be_kind_of(String)
          expect(key.hex.bytesize).to eq(32)
          expect(key.hex).to eq('5f4dcc3b5aa765d61d8327deb882cf99')
        end

        it 'generates a valid string of bytes' do
          expect(key.bytes).to be_kind_of(String)
          expect(key.bytes.bytesize).to eq(16)
          expect(key.bytes.bytes).to eq([95, 77, 204, 59, 90, 167, 101, 214, 29, 131, 39, 222, 184, 130, 207, 153])
        end
      end

      context 'with a 256 bit key' do
        let(:key) { EvpBytesToKey::Key.new('password', nil, 256, 0) }

        it 'generates a key from a password' do
          expect(key).to be_kind_of(EvpBytesToKey::Key)
        end

        it 'generates a valid hexadecimal value' do
          expect(key.hex).to be_kind_of(String)
          expect(key.hex.bytesize).to eq(64)
          expect(key.hex).to eq('5f4dcc3b5aa765d61d8327deb882cf992b95990a9151374abd8ff8c5a7a0fe08')
        end

        it 'generates a valid string of bytes' do
          expect(key.bytes).to be_kind_of(String)
          expect(key.bytes.bytesize).to eq(32)
          expect(key.bytes.bytes).to eq([95, 77, 204, 59, 90, 167, 101, 214, 29, 131, 39, 222, 184, 130, 207, 153, 43, 149, 153, 10, 145, 81, 55, 74, 189, 143, 248, 197, 167, 160, 254, 8])
        end
      end
    end
  end

  it 'has a version number' do
    expect(EvpBytesToKey::VERSION).not_to be nil
  end
end
