require 'bnet/errors'
require 'bnet/constants'
require 'digest/sha1'

require 'bnet/attributes/serial'
require 'bnet/attributes/secret'
require 'bnet/attributes/restorecode'

require 'bnet/authenticator/core'

module Bnet

  # The Battle.net authenticator
  class Authenticator

    # @!attribute [r] serial
    # @return [String] serial
    def serial
      @serial.to_s
    end

    # @!attribute [r] secret
    # @return [String] hexified secret
    def secret
      @secret.to_s
    end

    # @!attribute [r] restorecode
    # @return [String] restoration code
    def restorecode
      @restorecode.to_s
    end

    # @!attribute [r] region
    # @return [Symbol] region
    def region
      @serial.region
    end

    # Create a new authenticator with given serial and secret
    # @param serial [String]
    # @param secret [String]
    def initialize(serial, secret)
      @serial = Bnet::Attributes::Serial.new serial
      @secret = Bnet::Attributes::Secret.new secret
      @restorecode = Bnet::Attributes::Restorecode.new @serial, @secret
    end

    # Request a new authenticator from server
    # @param region [Symbol]
    # @return [Bnet::Authenticator]
    def self.request_authenticator(region)
      k = create_one_time_pad(37)

      payload_plain = "\1" + k + region.to_s + CLIENT_MODEL.ljust(16, "\0")[0, 16]
      e = rsa_encrypt_bin(payload_plain)

      response_body = request_for('new serial', region, ENROLLMENT_REQUEST_PATH, e)

      decrypted = decrypt_response(response_body[8, 37], k)

      Authenticator.new(decrypted[20, 17], decrypted[0, 20])
    end

    # Restore an authenticator from server
    # @param serial [String]
    # @param restorecode [String]
    # @return [Bnet::Authenticator]
    def self.restore_authenticator(serial, restorecode)
      serial = Bnet::Attributes::Serial.new serial
      restorecode = Bnet::Attributes::Restorecode.new restorecode

      # stage 1
      challenge = request_for('restore (stage 1)', serial.region, RESTORE_INIT_REQUEST_PATH, serial.normalized)

      # stage 2
      key = create_one_time_pad(20)

      digest = Digest::HMAC.digest(serial.normalized + challenge,
                                   restorecode.binary,
                                   Digest::SHA1)

      payload = serial.normalized + rsa_encrypt_bin(digest + key)

      response_body = request_for('restore (stage 2)', serial.region, RESTORE_VALIDATE_REQUEST_PATH, payload)

      Authenticator.new(serial, decrypt_response(response_body, key))
    end

    # Get server's time
    # @param region [Symbol]
    # @return [Integer] server timestamp in seconds
    def self.request_server_time(region)
      server_time_big_endian = request_for('server time', region, TIME_REQUEST_PATH)
      server_time_big_endian.unpack('Q>')[0].to_f / 1000
    end

    # Get token from given secret and timestamp
    # @param secret [String] hexified secret
    # @param timestamp [Integer] UNIX timestamp in seconds,
    #   defaults to current time
    # @return [String, Integer] token and the next timestamp token to change
    def self.get_token(secret, timestamp = nil)
      secret = Bnet::Attributes::Secret.new secret

      current = (timestamp || Time.now.getutc.to_i) / 30
      digest = Digest::HMAC.digest([current].pack('Q>'), secret.binary, Digest::SHA1)
      start_position = digest[19].ord & 0xf

      token = digest[start_position, 4].unpack('L>')[0] & 0x7fffffff

      return '%08d' % (token % 100000000), (current + 1) * 30
    end

    # Get authenticator's token from given timestamp
    # @param timestamp [Integer] UNIX timestamp in seconds,
    #   defaults to current time
    # @return [String, Integer] token and the next timestamp token to change
    def get_token(timestamp = nil)
      self.class.get_token(secret, timestamp)
    end

    # Hash representation of this authenticator
    # @return [Hash]
    def to_hash
      {
        :serial => serial,
        :secret => secret,
        :restorecode => restorecode,
        :region => region,
      }
    end

    # String representation of this authenticator
    # @return [String]
    def to_s
      to_hash.to_s
    end

  end

end
