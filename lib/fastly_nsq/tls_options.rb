module FastlyNsq
  class TlsOptions
    def initialize(context = nil)
      @context = context || {}
    end

    def to_h
      merge_contexts
      if @context.empty?
        {}
      else
        {
          tls_v1: true,
          tls_options: @context,
        }
      end
    end

    private

    def env_key
      ENV.fetch('NSQ_SSL_KEY', nil)
    end

    def env_certificate
      ENV.fetch('NSQ_SSL_CERTIFICATE', nil)
    end

    def env_ca_certificate
      ENV.fetch('NSQ_SSL_CA_CERTIFICATE', nil)
    end

    def verify_mode
      ENV.fetch('NSQ_SSL_VERIFY_MODE', nil)
    end

    def env_default_hash
      {
        key: env_key,
        certificate: env_certificate,
        ca_certificate: env_ca_certificate,
        verify_mode: verify_mode,
      }
    end

    def merge_contexts
      @context = env_default_hash.merge(@context).delete_if { |_, v| v.nil? }
    end
  end
end
