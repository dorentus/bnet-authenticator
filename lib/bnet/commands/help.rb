require 'bnet/command'

module Bnet

  module Commands

    class HelpCommand < Command

      def description
        'Print help message for this program or a command.'
      end

      def extra_params
        '[command]'
      end

      def run
        command = args.shift
        command = command.to_sym unless command.nil?
        raise InvalidCommandException.new(nil, command)
      end

    end

  end

end
