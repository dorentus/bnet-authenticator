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
        serial = @args.shift
        restorecode = @args.shift

        authenticator = Authenticator.new(
          :serial => serial,
          :restorecode => restorecode
        )
        puts authenticator.to_s
      end

    end

  end

end
