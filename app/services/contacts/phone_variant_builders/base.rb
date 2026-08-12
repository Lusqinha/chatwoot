# Base class for country-specific phone number variant builders.
# Each country builder inherits from this and implements:
# - country_code_pattern: regex identifying the country from an E.164 number
# - variants: the alternate equivalent forms of the number (excluding itself)
#   contact phone numbers and returns every equivalent form used for de-duplication.
class Contacts::PhoneVariantBuilders::Base
  def handles?(phone_number)
    phone_number.match?(country_code_pattern)
  end

  def variants(phone_number)
    raise NotImplementedError, 'Subclasses must implement #variants'
  end

  private

  def country_code_pattern
    raise NotImplementedError, 'Subclasses must implement #country_code_pattern'
  end
end
