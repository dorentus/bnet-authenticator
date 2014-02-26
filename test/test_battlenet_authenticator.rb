require 'coveralls'
Coveralls.wear_merged!

require 'test/unit'
require 'bnet/authenticator'

class Bnet::AuthenticatorTest < Test::Unit::TestCase
  DEFAULT_SERIAL = 'CN-1402-1943-1283'
  DEFAULT_SECRET = '4202aa2182640745d8a807e0fe7e34b30c1edb23'
  DEFAULT_RSCODE = '4CKBN08QEB'
  DEFAULT_REGION = :CN

  def test_load
    authenticator = Bnet::Authenticator.new(:serial => DEFAULT_SERIAL, :secret => DEFAULT_SECRET)
    is_default_authenticator authenticator
  end

  def test_argument_error
    assert_raise ::Bnet::Authenticator::BadInputError do
      Bnet::Authenticator.new
    end

    assert_raise ::Bnet::Authenticator::BadInputError do
      Bnet::Authenticator.new(:serial => 'ABC')
    end

    assert_raise ::Bnet::Authenticator::BadInputError do
      Bnet::Authenticator.new(:region => 'SG')
    end

    assert_raise ::Bnet::Authenticator::BadInputError do
      Bnet::Authenticator.new(:restorecode => 'DDDD')
    end
  end

  def test_request_new_serial
    begin
      authenticator = Bnet::Authenticator.new(:region => :US)
      assert_equal :US, authenticator.region
      assert_not_nil authenticator.serial
      assert_not_nil authenticator.secret
      assert_not_nil authenticator.restorecode
    rescue Bnet::Authenticator::RequestFailedError
    end
  end

  def test_restore
    begin
      authenticator = Bnet::Authenticator.new(:serial => DEFAULT_SERIAL, :restorecode => DEFAULT_RSCODE)
      is_default_authenticator authenticator
    rescue Bnet::Authenticator::RequestFailedError
    end
  end

  def test_request_server_time
    begin
      Bnet::Authenticator.request_server_time :EU
    rescue Bnet::Authenticator::RequestFailedError
    end
  end

  private

  def is_default_authenticator(authenticator)
    assert_equal DEFAULT_REGION, authenticator.region
    assert_equal DEFAULT_SERIAL, authenticator.serial
    assert_equal DEFAULT_SECRET, authenticator.secret
    assert_equal DEFAULT_RSCODE, authenticator.restorecode
    assert_equal ['61459300', 1347279360], authenticator.caculate_token(1347279358)
    assert_equal ['61459300', 1347279360], authenticator.caculate_token(1347279359)
    assert_equal ['23423634', 1347279390], authenticator.caculate_token(1347279360)
  end
end
