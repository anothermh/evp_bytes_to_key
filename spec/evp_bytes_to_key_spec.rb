# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
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
      let(:key_length) { 256 }
      let(:iv_length) { 16 }
      let(:key) { EvpBytesToKey::Key.new('password', 'saltsalt', key_length, iv_length) }
      let(:valid_key) { 'fdbdf3419fff98bdb0241390f62a9db35f4aba29d77566377997314ebfc709f2' }
      let(:valid_iv) { '0b5ca7b1081f94b1ac12e3c8ba87d05a' }

      it 'generates a key from a password' do
        expect(key).to be_kind_of(EvpBytesToKey::Key)
      end

      it 'generates a valid byte string key value' do
        expect(key.key).to be_kind_of(String)
        expect(key.key.bytesize).to eq(key_length / 8)
        expect(key.key.unpack1('H*')).to eq(valid_key)
      end

      it 'generates a valid hexadecimal key value' do
        expect(key.key_hex).to be_kind_of(String)
        expect(key.key_hex.bytesize).to eq(key_length / 8 * 2)
        expect(key.key_hex).to eq(valid_key)
      end

      it 'generates a valid byte string iv value' do
        expect(key.iv).to be_kind_of(String)
        expect(key.iv.bytesize).to eq(iv_length)
        expect(key.iv.unpack1('H*')).to eq(valid_iv)
      end

      it 'generates a valid hexadecimal iv value' do
        expect(key.iv_hex).to be_kind_of(String)
        expect(key.iv_hex.bytesize).to eq(iv_length * 2)
        expect(key.iv_hex).to eq(valid_iv)
      end
    end
  end

  it 'has a version number' do
    expect(EvpBytesToKey::VERSION).not_to be nil
  end
end
# rubocop:enable Metrics/BlockLength
