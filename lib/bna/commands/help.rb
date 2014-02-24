require 'bna/command'

module Bna

  class HelpCommand < Command

    def description
      'Print help message for this program or a command.'
    end

    def extra_params
      '[command]'
    end

    def setup_opts(opts)
    end

    def run
      command = args.shift
      command = command.to_sym unless command.nil?
      raise BadCommand.new(nil, command)
    end

  end

end
