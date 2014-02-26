Bnet::Authenticator
====
Ruby implementation of the Battle.net Mobile Authenticator.

[![Build Status](https://travis-ci.org/dorentus/bnet-authenticator.png?branch=master)](https://travis-ci.org/dorentus/bnet-authenticator)

Installation
====
    $ [sudo] gem install bnet-authenticator

Using the library
====
    >> require 'bnet/authenticator'

Request a new authenticator
----
    >> authenticator = Bnet::Authenticator.new(:region => :US)
    => Serial: US-1402-2552-9200
    Secret: c1307afe865735653d981771dff04ceb79b1a353
    Restoration Code: EQXCPB2YVE

Get a token
----
    >> authenticator.caculate_token
    => 80185191

Restore an authenticator from server
----
    >> Bnet::Authenticator.new(:serial => 'CN-1402-1943-1283', :restorecode => '4CKBN08QEB')
    => Serial: CN-1402-1943-1283
    Secret: 4202aa2182640745d8a807e0fe7e34b30c1edb23
    Restoration Code: 4CKBN08QEB

Initialize an authenticator with given serial and secret
----
    >> Bnet::Authenticator.new(:serial => 'CN-1402-1943-1283', :secret => '4202aa2182640745d8a807e0fe7e34b30c1edb23')
    => Serial: CN-1402-1943-1283
    Secret: 4202aa2182640745d8a807e0fe7e34b30c1edb23
    Restoration Code: 4CKBN08QEB

Using the command-line tool
====
Run `bna` and follow instructions.
