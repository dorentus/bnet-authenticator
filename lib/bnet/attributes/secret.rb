module Bnet
  module Attributes
    class Secret
      attr_reader :text

      def initialize(secret)
        secret = secret.to_s

        if secret =~ /[0-9a-f]{40}/i
          @text = secret
        elsif secret.length == 20  # treated as binary input
          @text = secret.unpack('C*').map{ |i| i.to_s(16).rjust(2, '0') }.join
        else
          raise BadInputError.new("bad secret #{secret}")
        end
      end

      def binary
        text.scan(/.{2}/).map{|s| s.to_i(16)}.pack('C*')
      end

      alias_method :to_s, :text
    end
  end
end
