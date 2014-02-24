require 'bna/command'

module Bna

  class RestoreCommand < Command

    def description
      "Restore an authenticator from server and save it."
    end

    def extra_params
      "<serial> <restorecode>"
    end

    def setup_opts(opts)
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
