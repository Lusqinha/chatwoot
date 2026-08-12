# Brazilian mobile numbers may appear with or without the mandatory "9" ninth
# digit (+5553991929394 and +555391929394 are the same line), so both forms must
# be treated as one contact. A real mobile is "9" + [6-9] + 8 digits, since the
# "9" was prepended to the legacy 6/7/8/9 numbers; that [6-9] guard keeps
# landlines (subscriber starting 2-5) out, so they are never merged.
class Contacts::PhoneVariantBuilders::Brazil < Contacts::PhoneVariantBuilders::Base
  WITH_NINTH_DIGIT = /\A\+55(\d{2})9([6-9]\d{7})\z/
  WITHOUT_NINTH_DIGIT = /\A\+55(\d{2})([6-9]\d{7})\z/

  def variants(phone_number)
    if (match = phone_number.match(WITH_NINTH_DIGIT))
      ["+55#{match[1]}#{match[2]}"]
    elsif (match = phone_number.match(WITHOUT_NINTH_DIGIT))
      ["+55#{match[1]}9#{match[2]}"]
    else
      []
    end
  end

  private

  def country_code_pattern
    /\A\+55/
  end
end
