require 'spec_helper'

RSpec.describe SSLContext do
  describe 'when SSL ENV variables are not set' do
    describe '.to_h' do
      it 'returns nil when initialized without parameters' do
        context = SSLContext.new

        expect(context.to_h).to be_nil
      end

      it 'returns an equivalent hash when all variables are defined' do
        ssl_context_hash = {
          key: 'key',
          certificate: 'certificate',
          ca_certificate: 'ca_certificate',
        }
        context = SSLContext.new(ssl_context_hash)

        expect(context.to_h).to eq(ssl_context_hash)
      end

      it 'does not add keys with nil values' do
        ssl_context_hash = {
          key: 'key',
          certificate: 'certificate',
        }
        context = SSLContext.new(ssl_context_hash)
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
    end

    after do
      ENV['NSQ_SSL_KEY'] = nil
      ENV['NSQ_SSL_CERTIFICATE'] = nil
      ENV['NSQ_SSL_CA_CERTIFICATE'] = nil
    end

    describe '.to_h' do
      it 'returns a hash of the env variables when no parameters are passed' do
        expected_hash = {
          key: ENV['NSQ_SSL_KEY'],
          certificate: ENV['NSQ_SSL_CERTIFICATE'],
          ca_certificate: ENV['NSQ_SSL_CA_CERTIFICATE'],
        }
        context = SSLContext.new

        expect(context.to_h).to eq(expected_hash)
      end

      it 'merges passed parameters and env variables' do
        passed_certificate = '/passed/certificate'
        expected_hash = {
          key: ENV['NSQ_SSL_KEY'],
          certificate: passed_certificate,
          ca_certificate: ENV['NSQ_SSL_CA_CERTIFICATE'],
        }
        context = SSLContext.new(certificate: passed_certificate)

        expect(context.to_h).to eq(expected_hash)
      end
    end
  end
end
