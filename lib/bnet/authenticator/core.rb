require 'digest/sha1'
require 'digest/hmac'
require 'net/http'
require 'bnet/support'
require 'bnet/authenticator/errors'

module Bnet

  class Authenticator

    module Core

      RSA_MOD = 104890018807986556874007710914205443157030159668034197186125678960287470894290830530618284943118405110896322835449099433232093151168250152146023319326491587651685252774820340995950744075665455681760652136576493028733914892166700899109836291180881063097461175643998356321993663868233366705340758102567742483097
      RSA_KEY = 257
      AUTHENTICATOR_HOSTS = {
        :CN => "mobile-service.battlenet.com.cn",
        :EU => "m.eu.mobileservice.blizzard.com",
        :US => "m.us.mobileservice.blizzard.com",
      }
      ENROLLMENT_REQUEST_PATH = '/enrollment/enroll.htm'
      TIME_REQUEST_PATH = '/enrollment/time.htm'
      RESTORE_INIT_REQUEST_PATH = '/enrollment/initiatePaperRestore.htm'
      RESTORE_VALIDATE_REQUEST_PATH = '/enrollment/validatePaperRestore.htm'

      RESTORECODE_MAP = (0..32).reduce({}) do |memo, c|
        memo[c] = case
                    when c < 10 then c + 48
                    else
                      c += 55
                      c += 1 if c > 72  # S
                      c += 1 if c > 75  # O
                      c += 1 if c > 78  # L
                      c += 1 if c > 82  # I
                      c
                  end
        memo
      end
      RESTORECODE_MAP_INVERSE = RESTORECODE_MAP.invert

      def self.normalize_options(options)
        return nil if options.nil?

        %w(serial region restorecode secret).each do |attr|
          if options.has_key? attr.to_sym
            options[attr.to_sym] = send "normalize_#{attr}".to_sym, options[attr.to_sym] do |value|
              raise BadInputError.new("bad #{attr} #{value}")
            end
          end
        end

        options[:serial] = prettify_serial(options[:serial]) if options.has_key?(:serial)

        options
      end

      def self.encode_restorecode(bin)
        bin.bytes.map do |v|
          RESTORECODE_MAP[v & 0x1f]
        end.as_bytes_to_bin
      end

      def self.extract_region(serial)
        serial.to_s[0, 2].upcase.to_sym
      end

      def self.caculate_token(secret, timestamp = nil)
        secret = normalize_secret secret do |invalid_secret|
          return nil
        end

        current = (timestamp || Time.now.getutc.to_i) / 30

        digest = Digest::HMAC.digest([current].pack('Q>'), secret.as_hex_to_bin, Digest::SHA1)

        start_position = digest[19].ord & 0xf

        token = '%08d' % (digest[start_position, 4].as_bin_to_i % 100000000)

        return token, (current + 1) * 30
      end

      def self.request_new_serial(region, model = nil)
        e, k = prepair_serial_request(region, model || 'bn/authenticator')

        # request to server
        response_body = request_for('new serial', region, ENROLLMENT_REQUEST_PATH, e)

        # the first 8 bytes be server timestamp in milliseconds
        # the rest 37 bytes, to be XORed with `k`
        decrypted = decrypt_response(response_body[8, 37], k)

        # now
        # the first 20 bytes be the authenticator secret
        # the rest 17 bytes be the authenticator serial (readable string begins with CN-, US-, EU-, etc.)
        secret = decrypted[0, 20]
        serial = decrypted[20, 17]

        return serial, secret.as_bin_to_hex
      end

      def self.request_restore(serial, restorecode)
        serial_normalized = normalize_serial(serial)
        region = extract_region(serial_normalized)
        restorecode_bin = decode_restorecode(restorecode)

        # stage 1
        challenge = request_for('restore (stage 1)', region, RESTORE_INIT_REQUEST_PATH, serial_normalized)

        # stage 2
        key = create_one_time_pad(20)

        digest = Digest::HMAC.digest(serial_normalized + challenge,
                                     restorecode_bin,
                                     Digest::SHA1)

        payload = serial_normalized + rsa_encrypted((digest + key).as_bin_to_i)

        response_body = request_for('restore (stage 2)', region, RESTORE_VALIDATE_REQUEST_PATH, payload)

        secret = decrypt_response(response_body, key).as_bin_to_hex

        return prettify_serial(serial), secret
      end

      def self.request_server_time(region)
        request_for('server time', region, TIME_REQUEST_PATH).as_bin_to_i.to_f / 1000
      end

      class << self

        def normalize_serial(serial)
          s = serial.to_s.gsub(/-/, '').upcase

          if block_given?
            region = extract_region(s)
            yield serial unless (AUTHENTICATOR_HOSTS.has_key?(region) && s =~ /\d{12}/)
          end

          s
        end

        def prettify_serial(serial)
          serial = normalize_serial(serial) { |bad_serial| return nil }
          "#{serial[0, 2]}-" + serial[2, 12].scan(/.{4}/).join('-')
        end

        def normalize_region(region)
          normalized_region = region.to_s.upcase.to_sym

          if block_given? && !AUTHENTICATOR_HOSTS.has_key?(normalized_region)
            yield region
          end

          normalized_region
        end

        def normalize_restorecode(restorecode)
          restorecode = restorecode.upcase

          if block_given? && !(restorecode =~ /[0-9A-Z]{10}/)
            yield restorecode
          end

          restorecode
        end

        def normalize_secret(secret)
          if block_given? && !(secret =~ /[0-9a-f]{40}/i)
            yield secret
          end

          secret
        end

        def create_one_time_pad(length)
          (0..1.0/0.0).reduce('') do |memo, i|
            break memo if memo.length >= length
            memo << Digest::SHA1.digest(rand().to_s)
          end[0, length]
        end

        def decode_restorecode(str)
          str.bytes.map do |c|
            RESTORECODE_MAP_INVERSE[c]
          end.as_bytes_to_bin
        end

        def decrypt_response(text, key)
          text.bytes.zip(key.bytes).reduce('') do |memo, pair|
            memo + (pair[0] ^ pair[1]).chr
          end
        end

        def rsa_encrypted(integer)
          (integer ** RSA_KEY % RSA_MOD).to_bin
        end

        def prepair_serial_request(region, model)
          # one-time key of 37 bytes
          k = create_one_time_pad(37)

          # make byte[56]
          #   00 byte[1]  固定为1
          #   01 byte[37] 37位的随机数据，只使用一次，用来解密服务器返回数据
          #   38 byte[2]  区域码: CN, US, EU, etc.
          #   40 byte[16] 设备模型数据(手机型号字符串，可随意)
          bytes = [1]
          bytes.concat(k.bytes.to_a)
          bytes.concat(region.to_s.bytes.take(2))
          bytes.concat(model.ljust(16, "\0").bytes.take(16))

          # encrypted using RSA
          e = rsa_encrypted(bytes.as_bytes_to_i)

          return e, k
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

end
