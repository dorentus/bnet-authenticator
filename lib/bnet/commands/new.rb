require 'bnet/command'

module Bnet

  module Commands

    class NewCommand < Command

      def description
        "Request a new authenticator from server."
      end

      def extra_params
        "[region (valid regions are: US|EU|CN)]"
      end

      def run
        region = args.shift || 'US'
        region = region.to_sym

        authenticator = Authenticator.request_authenticator(region)
        puts authenticator.to_s
      end

    end

  end

end
