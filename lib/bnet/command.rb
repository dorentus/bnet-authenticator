module Bnet

  class InvalidCommandException < Exception
    attr_accessor :command
    attr_accessor :message

    def initialize(message = nil, command = nil)
      @message = message
      @command = command
    end

  end

  class Command
    attr_accessor :options
    attr_accessor :parser
    attr_accessor :args

    def initialize
      @options = OpenStruct.new

      @parser = OptionParser.new do |opts|
        opts.banner = <<-END.gsub(/^\s+/, '')
          #{description}\n
          Usage: #{File.basename $0} #{name}#{" " + extra_params unless extra_params.nil?}
        END

        setup_opts(opts)
      end
    end

    def parse_and_run(args)
      parse args

      begin
        run
      rescue Bnet::Authenticator::BadInputError, Bnet::Authenticator::RequestFailedError => e
        raise Bnet::InvalidCommandException.new(e.message, name.to_sym)
      end
    end

    def help
      "* #{(name + ':').ljust(12)}#{parser.help}"
    end

    def name
      self.class.name.split('::').last.gsub(/Command$/, '').downcase
    end

    private

    def parse(args)
      begin
        parser.parse! args
      rescue OptionParser::InvalidOption => e
        e.class.module_eval { attr_accessor :command } unless e.respond_to? :command
        e.command = name.to_sym
        raise e
      end
      @args = args
    end

    protected

    def description
      # description of the command
    end

    def extra_params
      # extra params of the command
    end

    def setup_opts(opts)
      # fill @options
    end

    def run
      # can access @options
    end
  end

end
