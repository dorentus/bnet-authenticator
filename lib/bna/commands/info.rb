require 'bna/command'

module Bna

  class InfoCommand < Command

    def description
      "Print serial, secret and restoration code of an authenticator."
    end

    def extra_params
      "<serial> <secret>"
    end

    def setup_opts(opts)
    end

    def run
      serial = @args.shift
      secret = @args.shift

      authenticator = Authenticator.new(:serial => serial, :secret => secret)
      puts authenticator.to_s
    end

  end

end
