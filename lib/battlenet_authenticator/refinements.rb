class BattlenetAuthenticator

  module Refinements

    refine Array do
      def as_bytes_to_bin
        pack('C*')
      end

      def as_bytes_to_hex
        '%02x' * length % self
      end

      def as_bytes_to_i
        as_bytes_to_hex.to_i(16)
      end
    end

    refine Integer do
      def to_bin
        to_bytes.as_bytes_to_bin
      end

      def to_bytes
        to_s(16).scan(/.{2}/).map {|s| s.to_i(16)}
      end
    end

    refine String do
      def as_bin_to_i
        bytes.as_bytes_to_i
      end

      def as_bin_to_hex
        bytes.as_bytes_to_hex
      end

      def as_hex_to_bin
        to_i(16).to_bytes.as_bytes_to_bin
      end
    end

  end

end
