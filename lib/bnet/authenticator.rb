require 'bnet/support'
require 'bnet/authenticator/errors'
require 'bnet/authenticator/constants'
require 'digest/sha1'
require 'digest/hmac'
require 'net/http'

module Bnet

  # The Battle.net authenticator
  class Authenticator

    # @!attribute [r] serial
    # @return [String] serial
    attr_reader :serial

    # @!attribute [r] secret
    # @return [String] hexified secret
    attr_reader :secret

    # @!attribute [r] restorecode
    # @return [String] restoration code
    attr_reader :restorecode

    # @!attribute [r] region
    # @return [Symbol] region
    attr_reader :region

    # Create a new authenticator with given serial and secret
    # @param serial [String]
    # @param secret [String]
    def initialize(serial, secret)
      raise BadInputError.new("bad serial #{serial}") unless self.class.is_valid_serial?(serial)
      raise BadInputError.new("bad secret #{secret}") unless self.class.is_valid_secret?(secret)

      normalized_serial = self.class.normalize_serial(serial)

      @serial = self.class.prettify_serial(normalized_serial)
      @secret = secret
      @region = self.class.extract_region(normalized_serial)

      restorecode_bin = Digest::SHA1.digest(normalized_serial + secret.as_hex_to_bin)
      @restorecode = self.class.encode_restorecode(restorecode_bin.split(//).last(10).join)
    end

    # Request a new authenticator from server
    # @param region [Symbol]
    # @return [Bnet::Authenticator]
    def self.request_authenticator(region)
      region = region.to_s.upcase.to_sym
      raise BadInputError.new("bad region #{region}") unless is_valid_region?(region)

      k = create_one_time_pad(37)

      payload_plain = "\1" + k + region.to_s + CLIENT_MODEL.ljust(16, "\0")[0, 16]
      e = rsa_encrypted(payload_plain.as_bin_to_i)

      response_body = request_for('new serial', region, ENROLLMENT_REQUEST_PATH, e)

      decrypted = decrypt_response(response_body[8, 37], k)

      Authenticator.new(decrypted[20, 17], decrypted[0, 20].as_bin_to_hex)
    end

    # Restore an authenticator from server
    # @param serial [String]
    # @param restorecode [String]
    # @return [Bnet::Authenticator]
    def self.restore_authenticator(serial, restorecode)
      raise BadInputError.new("bad serial #{serial}") unless is_valid_serial?(serial)
      raise BadInputError.new("bad restoration code #{restorecode}") unless is_valid_restorecode?(restorecode)

      normalized_serial = normalize_serial(serial)
      region = extract_region(normalized_serial)

      # stage 1
      challenge = request_for('restore (stage 1)', region, RESTORE_INIT_REQUEST_PATH, normalized_serial)

      # stage 2
      key = create_one_time_pad(20)

      digest = Digest::HMAC.digest(normalized_serial + challenge,
                                   decode_restorecode(restorecode),
                                   Digest::SHA1)

      payload = normalized_serial + rsa_encrypted((digest + key).as_bin_to_i)

      response_body = request_for('restore (stage 2)', region, RESTORE_VALIDATE_REQUEST_PATH, payload)

      Authenticator.new(prettify_serial(normalized_serial), decrypt_response(response_body, key).as_bin_to_hex)
    end

    # Get server's time
    # @param region [Symbol]
    # @return [Integer] server timestamp in seconds
    def self.request_server_time(region)
      request_for('server time', region, TIME_REQUEST_PATH).as_bin_to_i.to_f / 1000
    end

    # Get token from given secret and timestamp
    # @param secret [String] hexified secret
    # @param timestamp [Integer] UNIX timestamp in seconds,
    #   defaults to current time
    # @return [String, Integer] token and the next timestamp token to change
    def self.get_token(secret, timestamp = nil)
      raise BadInputError.new("bad seret #{secret}") unless is_valid_secret?(secret)

      current = (timestamp || Time.now.getutc.to_i) / 30
      digest = Digest::HMAC.digest([current].pack('Q>'), secret.as_hex_to_bin, Digest::SHA1)
      start_position = digest[19].ord & 0xf
      token = '%08d' % (digest[start_position, 4].as_bin_to_i % 100000000)

      return token, (current + 1) * 30
    end

    # Get authenticator's token from given timestamp
    # @param timestamp [Integer] UNIX timestamp in seconds,
    #   defaults to current time
    # @return [String, Integer] token and the next timestamp token to change
    def get_token(timestamp = nil)
      self.class.get_token(@secret, timestamp)
    end

    # String representation of this authenticator
    # @return [String]
    def to_s
      "Serial: #{serial}\nSecret: #{secret}\nRestoration Code: #{restorecode}"
    end

    class << self
      def is_valid_serial?(serial)
        normalized_serial = normalize_serial(serial)
        normalized_serial =~ Regexp.new("^(#{AUTHENTICATOR_HOSTS.keys.join('|')})\\d{12}$") && is_valid_region?(extract_region(normalized_serial))
      end

      def normalize_serial(serial)
        serial.upcase.gsub(/-/, '')
      end

      def extract_region(serial)
        serial[0, 2].upcase.to_sym
      end

      def prettify_serial(serial)
        "#{serial[0, 2]}-" + serial[2, 12].scan(/.{4}/).join('-')
      end

      def is_valid_secret?(secret)
        secret =~ /[0-9a-f]{40}/i
      end

      def is_valid_region?(region)
        AUTHENTICATOR_HOSTS.has_key? region
      end

      def is_valid_restorecode?(restorecode)
        restorecode =~ /[0-9A-Z]{10}/
      end

      def encode_restorecode(bin)
        bin.bytes.map do |v|
          RESTORECODE_MAP[v & 0x1f]
        end.as_bytes_to_bin
      end

      def decode_restorecode(str)
        str.bytes.map do |c|
          RESTORECODE_MAP_INVERSE[c]
        end.as_bytes_to_bin
      end

      def create_one_time_pad(length)
        (0..1.0/0.0).reduce('') do |memo, i|
          break memo if memo.length >= length
          memo << Digest::SHA1.digest(rand().to_s)
        end[0, length]
      end

      def decrypt_response(text, key)
        text.bytes.zip(key.bytes).reduce('') do |memo, pair|
          memo + (pair[0] ^ pair[1]).chr
        end
      end

      def rsa_encrypted(integer)
        (integer ** RSA_KEY % RSA_MOD).to_bin
      end

      def request_for(label, region, path, body = nil)
        request = body.nil? ? Net::HTTP::Get.new(path) : Net::HTTP::Post.new(path)
        request.content_type = 'application/octet-stream'
        request.body = body unless body.nil?

        response = Net::HTTP.new(AUTHENTICATOR_HOSTS[region]).start do |http|
          http.request request
        end

        if response.code.to_i != 200
          raise RequestFailedError.new("Error requesting #{label}: #{response.code}")
        end

        response.body
      end

    end

  end

end
