module Bnet

  CLIENT_MODEL = 'bn/authenticator'
  RSA_MOD = "955e4bd989f3917d2f15544a7e0504eb\
             9d7bb66b6f8a2fe470e453c779200e5e\
             3ad2e43a02d06c4adbd8d328f1a426b8\
             3658e88bfd949b2af4eaf30054673a14\
             19a250fa4cc1278d12855b5b25818d16\
             2c6e6ee2ab4a350d401d78f6ddb99711\
             e72626b48bd8b5b0b7f3acf9ea3c9e00\
             05fee59e19136cdb7c83f2ab8b0a2a99".gsub(/\s+/, '').to_i(16)
  RSA_KEY = 257
  AUTHENTICATOR_HOSTS = {
    :CN => "mobile-service.battlenet.com.cn",
    :EU => "m.eu.mobileservice.blizzard.com",
    :US => "m.us.mobileservice.blizzard.com",
  }
  ENROLLMENT_REQUEST_PATH = '/enrollment/enroll.htm'
  TIME_REQUEST_PATH = '/enrollment/time.htm'
  RESTORE_INIT_REQUEST_PATH = '/enrollment/initiatePaperRestore.htm'
  RESTORE_VALIDATE_REQUEST_PATH = '/enrollment/validatePaperRestore.htm'

  RESTORECODE_MAP = {
    0=>48,  1=>49,  2=>50,  3=>51,  4=>52,
    5=>53,  6=>54,  7=>55,  8=>56,  9=>57,
    10=>65, 11=>66, 12=>67, 13=>68, 14=>69,
    15=>70, 16=>71, 17=>72, 18=>74, 19=>75,
    20=>77, 21=>78, 22=>80, 23=>81, 24=>82,
    25=>84, 26=>85, 27=>86, 28=>87, 29=>88,
    30=>89, 31=>90, 32=>91
  }
  RESTORECODE_MAP_INVERSE = RESTORECODE_MAP.invert

end
