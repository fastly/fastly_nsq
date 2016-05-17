module FastlyNsq
  class SSLContext
    def initialize(context = nil)
      @context = context || {}
    end

    def to_h
      merge_contexts
      if empty_context?
        nil
      else
        @context
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

    def env_default_hash
      {
        key: env_key,
        certificate: env_certificate,
        ca_certificate: env_ca_certificate,
      }
    end

    def merge_contexts
      @context = env_default_hash.merge(@context)
    end

    def empty_context?
      @context.all? { |_key, value| value.nil? }
    end
  end
end
