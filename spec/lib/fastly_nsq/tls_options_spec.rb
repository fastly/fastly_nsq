require 'spec_helper'

RSpec.describe FastlyNsq::TlsOptions do
  describe 'when SSL ENV variables are not set' do
    describe '.to_h' do
      it 'returns nil when initialized without parameters' do
        context = FastlyNsq::TlsOptions.new

        expect(context.to_h).to eq({})
      end

      it 'returns an equivalent hash when all variables are defined' do
        tls_options_hash = {
          key: 'key',
          certificate: 'certificate',
          ca_certificate: 'ca_certificate',
        }
        context = FastlyNsq::TlsOptions.new(tls_options_hash)

        expected_output = {
          tls_v1: true,
          tls_options: {
            key: 'key',
            certificate: 'certificate',
            ca_certificate: 'ca_certificate',
          },
        }
        expect(context.to_h).to eq(expected_output)
      end

      it 'does not add keys with nil values' do
        tls_options_hash = {
          key: 'key',
          certificate: 'certificate',
        }
        context = FastlyNsq::TlsOptions.new(tls_options_hash)
        ca_certificate = context.to_h[:ca_certificate]

        expect(ca_certificate).to be_nil
      end
    end
  end

  describe 'when SSL ENV variables are set' do
    before do
      ENV['NSQ_SSL_KEY'] = '/some/key'
      ENV['NSQ_SSL_CERTIFICATE'] = '/some/certificate'
      ENV['NSQ_SSL_CA_CERTIFICATE'] = '/some/ca_certificate'
      ENV['NSQ_SSL_VERIFY_MODE'] = 'value'
    end

    after do
      ENV['NSQ_SSL_KEY'] = nil
      ENV['NSQ_SSL_CERTIFICATE'] = nil
      ENV['NSQ_SSL_CA_CERTIFICATE'] = nil
      ENV['NSQ_SSL_VERIFY_MODE'] = nil
    end

    describe '.to_h' do
      it 'returns a hash of the env variables when no parameters are passed' do
        expected_hash = {
          tls_v1: true,
          tls_options: {
            key: ENV['NSQ_SSL_KEY'],
            certificate: ENV['NSQ_SSL_CERTIFICATE'],
            ca_certificate: ENV['NSQ_SSL_CA_CERTIFICATE'],
            verify_mode: ENV['NSQ_SSL_VERIFY_MODE'],
          },
        }
        context = FastlyNsq::TlsOptions.new

        expect(context.to_h).to eq(expected_hash)
      end

      it 'merges passed parameters and env variables' do
        passed_certificate = '/passed/certificate'
        expected_hash = {
          tls_v1: true,
          tls_options: {
            key: ENV['NSQ_SSL_KEY'],
            certificate: passed_certificate,
            ca_certificate: ENV['NSQ_SSL_CA_CERTIFICATE'],
            verify_mode: ENV['NSQ_SSL_VERIFY_MODE'],
          },
        }
        context = FastlyNsq::TlsOptions.new(certificate: passed_certificate)

        expect(context.to_h).to eq(expected_hash)
      end

      it 'removes keys that are nil' do
        expected_hash = {
          tls_v1: true,
          tls_options: {
            ca_certificate: ENV['NSQ_SSL_CA_CERTIFICATE'],
            verify_mode: ENV['NSQ_SSL_VERIFY_MODE'],
          },
        }
        context = FastlyNsq::TlsOptions.new(key: nil, certificate: nil)

        expect(context.to_h).to eq(expected_hash)
      end
    end
  end
end
