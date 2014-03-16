require 'bnet/command'

module Bnet

  module Commands

    class InfoCommand < Command

      def description
        "Print serial, secret and restoration code of an authenticator."
      end

      def extra_params
        "<serial> <secret>"
      end

      def run
        serial, secret = @args.shift(2)

        authenticator = Authenticator.new(serial, secret)
        puts authenticator.to_readable_text
      end

    end

  end

end
