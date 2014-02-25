require 'digest/sha1'
require 'digest/hmac'
require 'net/http'
require 'bnet/supports'

module Bnet

  class RequestFailedError < StandardError; end
  class BadInputError < StandardError; end

  class Authenticator

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

    attr_reader :serial
    attr_reader :secret
    attr_reader :restorecode
    attr_reader :region

    def initialize(options = {})
      options = self.class.normalize_options(options)

      if options.has_key?(:serial) && options.has_key?(:secret)
        @serial, @secret = options[:serial], options[:secret]
      elsif options.has_key?(:region)
        @serial, @secret = self.class.request_new_serial(options[:region], options[:model])
      elsif options.has_key?(:serial) && options.has_key?(:restorecode)
        @serial, @secret = self.class.request_restore(options[:serial], options[:restorecode])
      else
        raise BadInputError.new('invalid options')
      end
    end

    def restorecode
      return nil if @serial.nil? or @secret.nil?

      code_bin = Digest::SHA1.digest(self.class.normalize_serial(@serial) + @secret.as_hex_to_bin).reverse[0, 10].reverse
      self.class.encode_restorecode(code_bin)
    end

    def region
      self.class.extract_region(@serial)
    end

    def self.caculate_token(secret, timestamp = nil)
      secret = normalize_options(:secret => secret)[:secret]

      timestamp = Time.now.getutc.to_i if timestamp.nil?

      current = timestamp / 30
      next_timestamp = (current + 1) * 30

      digest = Digest::HMAC.digest([current].pack('Q>'), secret.as_hex_to_bin, Digest::SHA1)

      start_position = digest[19].ord & 0xf

      token = '%08d' % (digest[start_position, 4].as_bin_to_i % 100000000)

      return token, next_timestamp
    end

    def caculate_token(timestamp = nil)
      self.class.caculate_token(secret, timestamp)
    end

    def normalized_serial
      self.class.normalize_serial(@serial)
    end

    def self.request_server_time(region)
      request = Net::HTTP::Get.new(TIME_REQUEST_PATH)
      request.content_type = 'application/octet-stream'

      response = Net::HTTP.new(AUTHENTICATOR_HOSTS[region]).start do |http|
        http.request(request)
      end

      raise RequestFailedError.new("Error requesting server time: #{response.code}") if response.code.to_i(10) != 200

      response.body.as_bin_to_i.to_f / 1000.0
    end

    def self.normalize_serial(serial)
      return nil if serial.nil?
      serial.gsub(/-/, '').upcase
    end

    def self.prettify_serial(serial)
      return nil if serial.nil?
      serial = normalize_serial(serial)
      "#{serial[0, 2]}-" + serial[2, 12].scan(/.{4}/).join('-')
    end

    def to_s
      "Serial: #{serial}\nSecret: #{secret}\nRestoration Code: #{restorecode}"
    end

    private

    def self.normalize_options(options)
      if options.has_key?(:serial)
        normalized_serial = normalize_serial(options[:serial])
        region = extract_region(normalized_serial)

        if AUTHENTICATOR_HOSTS.has_key?(region) && normalized_serial =~ /\d{12}/
          options[:serial] = prettify_serial(normalized_serial)
        else
          raise BadInputError.new("bad serial #{options[:serial]}")
        end
      end

      if options.has_key?(:region)
        region = options[:region].to_s.upcase.to_sym
        raise BadInputError.new("unsupported region #{region}") unless AUTHENTICATOR_HOSTS.has_key?(region)

        options[:region] = region
      end

      if options.has_key?(:restorecode)
        restorecode = options[:restorecode].upcase

        raise BadInputError.new("bad restoration code #{restorecode}") unless restorecode =~ /[0-9A-Z]{10}/

        options[:restorecode] = restorecode
      end

      if options.has_key?(:secret)
        secret = options[:secret]
        raise BadInputError.new("bad secret #{secret}") unless secret =~ /[0-9a-f]{40}/i
      end

      options
    end

    def self.request_new_serial(region, model = nil)
      model ||= 'Motorola RAZR v3'

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
      e = (bytes.as_bytes_to_i ** RSA_KEY % RSA_MOD).to_bin

      # request to server
      request = Net::HTTP::Post.new(ENROLLMENT_REQUEST_PATH)
      request.content_type = 'application/octet-stream'
      request.body = e

      response = Net::HTTP.new(AUTHENTICATOR_HOSTS[region]).start do |http|
        http.request(request)
      end

      # server error
      #   note: server is unhappy with certain `k`s, such as:
      #     [206, 166, 17, 196, 68, 160, 142, 111, 216, 196, 170, 19, 49, 239, 101, 93, 114, 241, 57, 223, 150, 80, 219, 114, 95, 20, 42, 142, 193, 115, 79, 71, 189, 147, 242, 111, 27].as_bytes_to_bin
      raise RequestFailedError.new("Error requesting for new serial: #{response.code}") if response.code.to_i(10) != 200

      # the first 8 bytes be server timestamp in milliseconds
      # server_timestamp_in_ms = response.body[0, 8].as_bin_to_i

      # the rest 37 bytes, to be XORed with `k`
      decrypted = response.body[8, 37].bytes.zip(k.bytes).reduce('') do |memo, pair|
        memo << (pair[0] ^ pair[1]).chr
      end

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
      request = Net::HTTP::Post.new(RESTORE_INIT_REQUEST_PATH)
      request.content_type = 'application/octet-stream'
      request.body = serial_normalized

      response = Net::HTTP.new(AUTHENTICATOR_HOSTS[region]).start do |http|
        http.request(request)
      end

      raise RequestFailedError.new("Error requesting for restore (stage 1): #{response.code}") if response.code.to_i(10) != 200

      # stage 2
      challenge = response.body

      key = create_one_time_pad(20)

      digest = Digest::HMAC.digest(serial_normalized + challenge,
                                   restorecode_bin,
                                   Digest::SHA1)

      payload = serial_normalized
      payload += ((digest+key).as_bin_to_i ** RSA_KEY % RSA_MOD).to_bin

      request = Net::HTTP::Post.new(RESTORE_VALIDATE_REQUEST_PATH)
      request.content_type = 'application/octet-stream'
      request.body = payload

      response = Net::HTTP.new(AUTHENTICATOR_HOSTS[region]).start do |http|
        http.request(request)
      end

      raise RequestFailedError.new("Error requesting for restore (stage 2): #{response.code}") if response.code.to_i(10) != 200

      secret = response.body.bytes.zip(key.bytes).reduce('') do |memo, pair|
        memo << (pair[0] ^ pair[1]).chr
      end.as_bin_to_hex

      return prettify_serial(serial), secret
    end

    def self.extract_region(serial)
      serial[0, 2].upcase.to_sym
    end

    def self.create_one_time_pad(length)
      (0..1.0/0.0).reduce('') do |memo, i|
        break memo if memo.length >= length
        memo << Digest::SHA1.digest(rand().to_s)
      end[0, length]
    end

    def self.encode_restorecode(bin)
      bin.bytes.map do |v|
        RESTORECODE_MAP[v & 0x1f]
      end.as_bytes_to_bin
    end

    def self.decode_restorecode(str)
      str.bytes.map do |c|
        RESTORECODE_MAP_INVERSE[c]
      end.as_bytes_to_bin
    end

  end

end
