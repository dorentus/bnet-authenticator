require 'bnet/command'

module Bnet

  module Commands

    class RestoreCommand < Command

      def description
        "Restore an authenticator from server and save it."
      end

      def extra_params
        "<serial> <restorecode>"
      end

      def run
        serial, restorecode = @args.shift(2)

        authenticator = Authenticator.restore_authenticator(serial, restorecode)
        puts authenticator.to_readable_text
      end

    end

  end

end
