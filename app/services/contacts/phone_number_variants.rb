# Returns every equivalent representation of a phone number so the same person
# isn't stored as duplicate contacts (e.g. a Brazilian mobile with and without
# the ninth digit). Country-specific rules live in Contacts::PhoneVariantBuilders::*,
# Numbers without a matching country builder return only themselves and are unaffected.
class Contacts::PhoneNumberVariants
  BUILDERS = [
    Contacts::PhoneVariantBuilders::Brazil
  ].freeze

  def initialize(phone_number)
    @phone_number = phone_number
  end

  def all
    return [phone_number] if phone_number.blank?

    builder = BUILDERS.map(&:new).find { |candidate| candidate.handles?(phone_number) }
    [phone_number, *builder&.variants(phone_number)].uniq
  end

  private

  attr_reader :phone_number
end
