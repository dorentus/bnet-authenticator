require 'bnet/authenticator/core'

module Bnet

  # The battle.net authenticator
  class Authenticator

    # @!attribute [r] serial
    #   @return [String] the serial of the authenticator
    attr_reader :serial

    # @!attribute [r] secret
    #   @return [String] hexified secret of the authenticator
    attr_reader :secret

    # @!attribute [r] restorecode
    #   @return [String] the restoration code of the authenticator
    attr_reader :restorecode

    # @!attribute [r] region
    #   @return [Symbol] the region of the authenticator
    attr_reader :region

    # Create a new authenticator object
    # @param options [Hash] read the examples for more infomation
    #
    # == Examples:
    #   >> # Create an authenticator object with given serial and secret
    #   >> Bnet::Authenticator.new(:serial => 'CN-1402-1943-1283', :secret => '4202aa2182640745d8a807e0fe7e34b30c1edb23')
    #   => Serial: CN-1402-1943-1283
    #   Secret: 4202aa2182640745d8a807e0fe7e34b30c1edb23
    #   Restoration Code: 4CKBN08QEB
    #
    #   >> # Request server for a new authenticator
    #   >> Bnet::Authenticator.new(:region => :US)
    #   => Serial: US-1402-2552-9200
    #   Secret: c1307afe865735653d981771dff04ceb79b1a353
    #   Restoration Code: EQXCPB2YVE
    #
    #   >> # Reqeust to restore an authenticator
    #   >> Bnet::Authenticator.new(:serial => 'CN-1402-1943-1283', :restorecode => '4CKBN08QEB')
    #   => Serial: CN-1402-1943-1283
    #   Secret: 4202aa2182640745d8a807e0fe7e34b30c1edb23
    #   Restoration Code: 4CKBN08QEB
    #
    def initialize(options = {})
      options = Core.normalize_options(options)

      if options.has_key?(:serial) && options.has_key?(:secret)
        @serial, @secret = options[:serial], options[:secret]
      elsif options.has_key?(:region)
        @serial, @secret = Core.request_new_serial(options[:region], options[:model])
      elsif options.has_key?(:serial) && options.has_key?(:restorecode)
        @serial, @secret = Core.request_restore(options[:serial], options[:restorecode])
      else
        raise BadInputError.new('invalid options')
      end
    end

    # Get the restoration code of this authenticator
    # @return [String]
    def restorecode
      return nil if @serial.nil? or @secret.nil?

      code_bin = Digest::SHA1.digest(Core.normalize_serial(@serial) + @secret.as_hex_to_bin).reverse[0, 10].reverse
      Core.encode_restorecode(code_bin)
    end

    # Get the region of this authenticator
    # @return [Symbol]
    def region
      Core.extract_region(@serial)
    end

    # Caculate token using this authenticator's secret and given timestamp
    # (in seconds, defaults to current timestamp)
    #
    # @param timestamp [Integer] a UNIX timestamp in seconds
    # @return [String] current token
    def caculate_token(timestamp = nil)
      Core.caculate_token(@secret, timestamp)
    end

    # String representation of this authenticator
    # @return [String]
    def to_s
      "Serial: #{serial}\nSecret: #{secret}\nRestoration Code: #{restorecode}"
    end

    # Caculate token using given secret and timestamp
    # (in seconds, defaults to current timestamp)
    #
    # @param secret [String] hexified secret string of an authenticator
    # @param timestamp [Integer] a UNIX timestamp in seconds
    # @return [String] current token
    def self.caculate_token(secret, timestamp = nil)
      Core.caculate_token(secret, timestamp)
    end

    # Get server's time
    #
    # @param region [Symbol]
    # @return [Integer] server timestamp in seconds
    def self.request_server_time(region)
      Core.request_server_time(region)
    end

  end

end
