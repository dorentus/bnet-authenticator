require 'net/http'
require 'digest/sha1'

module Bnet

  class Authenticator

    class << self

      def create_one_time_pad(length)
        (0..1.0/0.0).reduce('') do |memo, i|
          break memo if memo.length >= length
          memo << Digest::SHA1.hexdigest(rand().to_s)
        end[0, length]
      end

      def decrypt_response(text, key)
        text.bytes.zip(key.bytes).reduce('') do |memo, pair|
          memo + (pair[0] ^ pair[1]).chr
        end
      end

      def rsa_encrypt_bin(bin)
        i = bin.unpack('C*').map{ |i| i.to_s(16).rjust(2, '0') }.join.to_i(16)
        (i ** RSA_KEY % RSA_MOD).to_s(16).scan(/.{2}/).map {|s| s.to_i(16)}.pack('C*')
      end

      def request_for(label, region, path, body = nil)
        raise BadInputError.new("bad region #{region}") unless AUTHENTICATOR_HOSTS.has_key? region

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
