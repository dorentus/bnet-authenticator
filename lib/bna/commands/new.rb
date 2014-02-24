require 'bna/command'

module Bna

  class NewCommand < Command

    def description
      "Request a new authenticator from server."
    end

    def extra_params
      "[region (valid regions are: US|EU|CN)]"
    end

    def setup_opts(opts)
    end

    def run
      region = args.shift || 'US'
      region = region.to_sym

      authenticator = Authenticator.new(:region => region)
      puts authenticator.to_s
    end

  end

end
