require 'coveralls'
Coveralls.wear_merged!

gem "minitest"
require 'minitest/autorun'
require 'bnet/authenticator'

class Bnet::AuthenticatorTest < Minitest::Test
  DEFAULT_SERIAL = 'CN-1402-1943-1283'
  DEFAULT_SECRET = '4202aa2182640745d8a807e0fe7e34b30c1edb23'
  DEFAULT_RSCODE = '4CKBN08QEB'
  DEFAULT_REGION = :CN

  def test_load
    authenticator = Bnet::Authenticator.new(DEFAULT_SERIAL, DEFAULT_SECRET)
    is_default_authenticator authenticator
  end

  def test_argument_error
    assert_raises ::Bnet::Authenticator::BadInputError do
      Bnet::Authenticator.new('ABC', '')
    end

    assert_raises ::Bnet::Authenticator::BadInputError do
      Bnet::Authenticator.request_authenticator('SG')
    end

    assert_raises ::Bnet::Authenticator::BadInputError do
      Bnet::Authenticator.restore_authenticator('DDDD', 'EEE')
    end
  end

  def test_request_new_serial
    begin
      authenticator = Bnet::Authenticator.request_authenticator(:US)
      assert_equal :US, authenticator.region
      refute_nil authenticator.serial
      refute_nil authenticator.secret
      refute_nil authenticator.restorecode
    rescue Bnet::Authenticator::RequestFailedError => e
      puts e
    end
  end

  def test_restore
    begin
      authenticator = Bnet::Authenticator.restore_authenticator(DEFAULT_SERIAL, DEFAULT_RSCODE)
      is_default_authenticator authenticator
    rescue Bnet::Authenticator::RequestFailedError => e
      puts e
    end
  end

  def test_request_server_time
    begin
      Bnet::Authenticator.request_server_time :EU
    rescue Bnet::Authenticator::RequestFailedError => e
      puts e
    end
  end

  private

  def is_default_authenticator(authenticator)
    assert_equal DEFAULT_REGION, authenticator.region
    assert_equal DEFAULT_SERIAL, authenticator.serial
    assert_equal DEFAULT_SECRET, authenticator.secret
    assert_equal DEFAULT_RSCODE, authenticator.restorecode
    assert_equal ['61459300', 1347279360], authenticator.get_token(1347279358)
    assert_equal ['61459300', 1347279360], authenticator.get_token(1347279359)
    assert_equal ['23423634', 1347279390], authenticator.get_token(1347279360)
  end
end
