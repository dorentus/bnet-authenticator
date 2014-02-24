require 'bna/command'

module Bna

  class TokenCommand < Command

    def description
      "Print current token for giving secret."
    end

    def extra_params
      "[-r] [--repeat] <secret>"
    end

    def setup_opts(opts)
      @options.repeat = false
      opts.on("-r", "--repeat", "Keep printing updated token") do
        @options.repeat = true
      end
    end

    def run
      secret = @args.shift

      token, next_timestamp = Authenticator.caculate_token(secret)

      puts token
      if @options.repeat
        interrupted = false
        trap("INT") { interrupted = true } # traps Ctrl-C

        until interrupted do
          sleep 1
          if Time.now.getutc.to_i < next_timestamp
            if $stdout.tty?
              diff = next_timestamp - Time.now.getutc.to_i
              case
              when diff > 25 then h, c = 1, 32
              when diff > 20 then h, c = 0, 32
              when diff > 15 then h, c = 1, 33
              when diff > 10 then h, c = 0, 33
              when diff > 5  then h, c = 0, 31
              else
                h, c = 1, 31
              end
              puts "\e[%d;%dm%02d\e[1A\e[0m" % [h, c, diff]
            end
            next
          end
          token, next_timestamp = Authenticator.caculate_token(secret)
          puts token
        end
      end
    end

  end

end
