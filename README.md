Bnet::Authenticator
====
Ruby implementation of the Battle.net Mobile Authenticator.

[![Gem Version](https://badge.fury.io/rb/bnet-authenticator.png)](http://badge.fury.io/rb/bnet-authenticator)

[![Build Status](https://travis-ci.org/dorentus/bnet-authenticator.svg?branch=master)](https://travis-ci.org/dorentus/bnet-authenticator) [![Dependency Status](https://gemnasium.com/dorentus/bnet-authenticator.png)](https://gemnasium.com/dorentus/bnet-authenticator) [![Coverage Status](https://coveralls.io/repos/dorentus/bnet-authenticator/badge.png)](https://coveralls.io/r/dorentus/bnet-authenticator) [![Code Climate](https://codeclimate.com/github/dorentus/bnet-authenticator.png)](https://codeclimate.com/github/dorentus/bnet-authenticator)

Installation
====
    $ [sudo] gem install bnet-authenticator

Using the library
====
    >> require 'bnet/authenticator'

Request a new authenticator
----
    >> authenticator = Bnet::Authenticator.request_authenticator(:US)
    => #<Bnet::Authenticator:0x007f83599ae848 @serial="US-1403-1677-5336", @secret="33a107e6a2927a2aa1be99cfe7b2d08c092a7a2a", @region=:US, @restorecode="4YV9XZVNMX">

Get a token
----
    >> authenticator.get_token
    => ["18338810", 1394965110]

Restore an authenticator from server
----
    >> Bnet::Authenticator.restore_authenticator('CN-1402-1943-1283', '4CKBN08QEB')
    => #<Bnet::Authenticator:0x007f83599cf458 @serial="CN-1402-1943-1283", @secret="4202aa2182640745d8a807e0fe7e34b30c1edb23", @region=:CN, @restorecode="4CKBN08QEB">

Initialize an authenticator with given serial and secret
----
    >> Bnet::Authenticator.new('CN-1402-1943-1283', '4202aa2182640745d8a807e0fe7e34b30c1edb23')
    => #<Bnet::Authenticator:0x007f8359a17500 @serial="CN-1402-1943-1283", @secret="4202aa2182640745d8a807e0fe7e34b30c1edb23", @region=:CN, @restorecode="4CKBN08QEB">

Using the command-line tool
====
Run `bna` and follow instructions.
