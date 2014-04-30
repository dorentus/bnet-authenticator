module Bnet
  module Attributes
    class Serial
      attr_reader :normalized

      def initialize(serial)
        serial = serial.to_s.upcase.gsub(/-/, '')
        raise BadInputError.new("bad serial #{serial}") unless serial =~ Regexp.new("^(#{AUTHENTICATOR_HOSTS.keys.join('|')})\\d{12}$")
        @normalized = serial
      end

      def prettified
        "#{normalized[0, 2]}-" + normalized[2, 12].scan(/.{4}/).join('-')
      end

      def region
        normalized[0, 2].upcase.to_sym
      end

      alias_method :to_s, :prettified
    end
  end
end
