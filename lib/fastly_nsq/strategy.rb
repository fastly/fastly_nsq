module FastlyNsq
  module Strategy


    module_function

    def for_queue
      real_queue || fake_queue || error
    end

    private_class_method

    ERR_MESSAGE = "You must set ENV['FAKE_QUEUE'] to either true or false".freeze

    def error
      raise InvalidParameterError, ERR_MESSAGE
    end

    FALSY_VALUES  = [false, 0, '0', 'false', 'FALSE', 'off', 'OFF', nil].freeze
    TRUTHY_VALUES = [true, 1, '1', 'true', 'TRUE', 'on', 'ON'].freeze

    def fake_queue
      FastlyNsq::FakeBackend if should_use_fake_queue?
    end

    def should_use_real_queue?
      FALSY_VALUES.include? ENV['FAKE_QUEUE']
    end

    def real_queue
      Nsq if should_use_real_queue?
    end

    def should_use_fake_queue?
      TRUTHY_VALUES.include? ENV['FAKE_QUEUE']
    end
  end
end
