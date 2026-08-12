# Rejects a contact whose phone number, in any of its country-specific variants
# (e.g. a Brazilian mobile with or without the ninth digit), already belongs to
# another contact in the same account, avoiding duplicates for the same person.
class PhoneNumberUniquenessValidator < ActiveModel::Validator
  def validate(record)
    return if record.phone_number.blank? || record.account_id.blank?
    return unless record.phone_number_changed?

    variants = Contacts::PhoneNumberVariants.new(record.phone_number).all
    duplicate = Contact.where(account_id: record.account_id, phone_number: variants).where.not(id: record.id)
    record.errors.add(:phone_number, :taken) if duplicate.exists?
  end
end
