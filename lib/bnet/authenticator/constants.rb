module Bnet

  class Authenticator

    CLIENT_MODEL = 'bn/authenticator'
    RSA_MOD = 104890018807986556874007710914205443157030159668034197186125678960287470894290830530618284943118405110896322835449099433232093151168250152146023319326491587651685252774820340995950744075665455681760652136576493028733914892166700899109836291180881063097461175643998356321993663868233366705340758102567742483097
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

    RESTORECODE_MAP = (0..32).reduce({}) do |memo, c|
      memo[c] = case
                  when c < 10 then c + 48
                  else
                    c += 55
                    c += 1 if c > 72  # S
                    c += 1 if c > 75  # O
                    c += 1 if c > 78  # L
                    c += 1 if c > 82  # I
                    c
                end
      memo
    end
    RESTORECODE_MAP_INVERSE = RESTORECODE_MAP.invert

  end

end
