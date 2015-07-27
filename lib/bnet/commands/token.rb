require 'bnet/command'

module Bnet

  module Commands

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

        token, next_timestamp = Authenticator.get_token(secret)

        if @options.repeat
          interrupted = false
          trap("INT") { interrupted = true } # traps Ctrl-C

          until interrupted do
            sleep 1

            if Time.now.getutc.to_i < next_timestamp
              seconds = next_timestamp - Time.now.getutc.to_i
              h, c = color_of(seconds)
              puts "\e[s\e[%d;%dm\e[5m%02d\e[25m\t->\t%s\t<-\e[1A\e[0m\e[u" % [h, c, seconds, token]
              next
            end

            token, next_timestamp = Authenticator.get_token(secret)
          end
        else
          puts token
        end
      end

      private

      def color_of(seconds)
        case
          when seconds > 25 then h, c = 1, 32
          when seconds > 20 then h, c = 0, 32
          when seconds > 15 then h, c = 1, 33
          when seconds > 10 then h, c = 0, 33
          when seconds > 5  then h, c = 0, 31
          else
            h, c = 1, 31
        end

        [h, c]
      end

    end

  end

end
