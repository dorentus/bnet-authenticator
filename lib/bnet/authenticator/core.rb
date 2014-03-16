require 'bnet/support'
require 'bnet/constants'
require 'digest/sha1'
require 'digest/hmac'
require 'net/http'

module Bnet

  class Authenticator

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
