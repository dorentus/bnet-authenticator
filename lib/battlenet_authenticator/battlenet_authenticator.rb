require 'digest/sha1'
require 'digest/hmac'
require 'net/http'
require 'battlenet_authenticator/refinements'
require 'battlenet_authenticator/exceptions'

class BattlenetAuthenticator
  using Refinements
end
