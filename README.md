# Bnet::Authenticator
Ruby implementation of the Battle.net Mobile Authenticator.

[![Gem Version](http://img.shields.io/gem/v/bnet-authenticator.svg?style=flat)](http://badge.fury.io/rb/bnet-authenticator)
[![Dependency Status](http://img.shields.io/gemnasium/dorentus/bnet-authenticator.svg?style=flat)](https://gemnasium.com/dorentus/bnet-authenticator)

[![Build Status](http://img.shields.io/travis/dorentus/bnet-authenticator.svg?style=flat)](https://travis-ci.org/dorentus/bnet-authenticator)

[![Coverage Status](http://img.shields.io/coveralls/dorentus/bnet-authenticator.svg?style=flat)](https://coveralls.io/r/dorentus/bnet-authenticator)

[![Code Climate](http://img.shields.io/codeclimate/github/dorentus/bnet-authenticator.svg?style=flat)](https://codeclimate.com/github/dorentus/bnet-authenticator)
[![Coverage Status from Code Climate](http://img.shields.io/codeclimate/coverage/github/dorentus/bnet-authenticator.svg?style=flat)](https://codeclimate.com/github/dorentus/bnet-authenticator)

<sub>FYI: Badge images provided by http://shields.io/</sub>

## Installation
```bash
$ [sudo] gem install bnet-authenticator
```

## Using the library
```irb
>> require 'bnet/authenticator'
```

### Request a new authenticator
```irb
>> authenticator = Bnet::Authenticator.request_authenticator(:US)
=> {:serial=>"US-1405-0242-3258", :secret=>"778275450e5c3e092bc4fe901cd7c11241166c88", :restorecode=>"0WCRH9Z926", :region=>:US}
```

### Get a token
```irb
>> authenticator.get_token
=> ["38530888", 1399038930]
```

### Restore an authenticator from server
```irb
>> Bnet::Authenticator.restore_authenticator('CN-1402-1943-1283', '4CKBN08QEB')
=> {:serial=>"CN-1402-1943-1283", :secret=>"4202aa2182640745d8a807e0fe7e34b30c1edb23", :restorecode=>"4CKBN08QEB", :region=>:CN}
```

### Initialize an authenticator with given serial and secret
```irb
>> Bnet::Authenticator.new('CN-1402-1943-1283', '4202aa2182640745d8a807e0fe7e34b30c1edb23')
=> {:serial=>"CN-1402-1943-1283", :secret=>"4202aa2182640745d8a807e0fe7e34b30c1edb23", :restorecode=>"4CKBN08QEB", :region=>:CN}
```

## Using the command-line tool
Run `bna` and follow instructions.
