# frozen_string_literal: true

require 'rails_helper'

require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe Contact do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
  end

  context 'with associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:conversations).dependent(:destroy_async) }
  end

  describe 'concerns' do
    it_behaves_like 'avatarable'

    it 'accepts webp avatars' do
      contact = build(:contact, account: create(:account))
      contact.avatar.attach(get_blob_for(Rails.root.join('spec/assets/avatar.png'), 'image/webp'))

      expect(contact).to be_valid
    end
  end

  context 'when prepare contact attributes before validation' do
    it 'sets email to lowercase' do
      contact = create(:contact, email: 'Test@test.com')
      expect(contact.email).to eq('test@test.com')
      expect(contact.contact_type).to eq('lead')
    end

    it 'sets email to nil when empty string' do
      contact = create(:contact, email: '')
      expect(contact.email).to be_nil
      expect(contact.contact_type).to eq('visitor')
    end

    it 'sets custom_attributes to {} when nil' do
      contact = create(:contact, custom_attributes: nil)
      expect(contact.custom_attributes).to eq({})
    end

    it 'sets custom_attributes to {} when empty string' do
      contact = create(:contact, custom_attributes: '')
      expect(contact.custom_attributes).to eq({})
    end

    it 'sets additional_attributes to {} when nil' do
      contact = create(:contact, additional_attributes: nil)
      expect(contact.additional_attributes).to eq({})
    end

    it 'sets additional_attributes to {} when empty string' do
      contact = create(:contact, additional_attributes: '')
      expect(contact.additional_attributes).to eq({})
    end
  end

  context 'when phone number format' do
    it 'will throw error for existing invalid phone number' do
      contact = create(:contact)
      expect { contact.update!(phone_number: '123456789') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'updates phone number when adding valid phone number' do
      contact = create(:contact)
      expect(contact.update!(phone_number: '+12312312321')).to be true
      expect(contact.phone_number).to eq '+12312312321'
    end
  end

  context 'when a Brazilian mobile duplicates across the ninth digit' do
    let(:account) { create(:account) }

    it 'creates the contact when no equivalent number exists yet' do
      aggregate_failures do
        expect(build(:contact, account: account, phone_number: '+5553991929394')).to be_valid
        expect(build(:contact, account: account, phone_number: '+555391929394')).to be_valid
      end
    end

    it 'blocks a number without the ninth digit when one with it already exists' do
      create(:contact, account: account, phone_number: '+5553991929394')
      duplicate = build(:contact, account: account, phone_number: '+555391929394')

      aggregate_failures do
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:phone_number]).to include('has already been taken')
      end
    end

    it 'still blocks an exact duplicate phone number' do
      create(:contact, account: account, phone_number: '+5553991929394')

      expect(build(:contact, account: account, phone_number: '+5553991929394')).not_to be_valid
    end

    it 'allows a blank phone number' do
      create(:contact, account: account, phone_number: nil)

      expect(build(:contact, account: account, phone_number: nil)).to be_valid
    end

    it 'blocks a number with the ninth digit when one without it already exists' do
      create(:contact, account: account, phone_number: '+555391929394')
      duplicate = build(:contact, account: account, phone_number: '+5553991929394')

      expect(duplicate).not_to be_valid
    end

    it 'blocks a new number when both ninth-digit variants already exist (legacy duplicates)' do
      create(:contact, account: account, phone_number: '+5553991929394')
      build(:contact, account: account, phone_number: '+555391929394').save(validate: false)

      expect(build(:contact, account: account, phone_number: '+5553991929394')).not_to be_valid
    end

    it 'allows the same mobile number in a different account' do
      create(:contact, account: account, phone_number: '+5553991929394')

      expect(build(:contact, account: create(:account), phone_number: '+555391929394')).to be_valid
    end

    it 'does not block a Brazilian landline that shares digits with a mobile' do
      create(:contact, account: account, phone_number: '+555332221111')

      expect(build(:contact, account: account, phone_number: '+5553932221111')).to be_valid
    end

    it 'does not block numbers from other countries' do
      create(:contact, account: account, phone_number: '+12025550123')

      expect(build(:contact, account: account, phone_number: '+12025550124')).to be_valid
    end

    it 'still allows saving the existing contact itself' do
      contact = create(:contact, account: account, phone_number: '+5553991929394')

      expect(contact.update(name: 'Updated')).to be true
    end

    it 'allows editing other attributes of a contact that has a legacy duplicate' do
      create(:contact, account: account, phone_number: '+5553991929394')
      contact = build(:contact, account: account, phone_number: '+555391929394')
      contact.save(validate: false)

      expect(contact.update(name: 'Renamed')).to be true
    end

    it 'still blocks changing a phone number to an existing contact variant' do
      create(:contact, account: account, phone_number: '+5553991929394')
      contact = create(:contact, account: account, phone_number: '+554133334444')

      expect(contact.update(phone_number: '+555391929394')).to be false
    end
  end

  context 'when email format' do
    it 'will throw error for existing invalid email' do
      contact = create(:contact)
      expect { contact.update!(email: '<2324234234') }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'updates email when adding valid email' do
      contact = create(:contact)
      expect(contact.update!(email: 'test@test.com')).to be true
      expect(contact.email).to eq 'test@test.com'
    end
  end

  context 'when city and country code passed in additional attributes' do
    it 'updates location and country code' do
      contact = create(:contact, additional_attributes: { city: 'New York', country: 'US' })
      expect(contact.location).to eq 'New York'
      expect(contact.country_code).to eq 'US'
    end
  end

  context 'when a contact is created' do
    it 'has contact type "visitor" by default' do
      contact = create(:contact)
      expect(contact.contact_type).to eq 'visitor'
    end

    it 'has contact type "lead" when email is present' do
      contact = create(:contact, email: 'test@test.com')
      expect(contact.contact_type).to eq 'lead'
    end

    it 'has contact type "lead" when contacted through a social channel' do
      contact = create(:contact, additional_attributes: { social_facebook_user_id: '123' })
      expect(contact.contact_type).to eq 'lead'
    end
  end

  describe '.resolved_contacts' do
    let(:account) { create(:account) }

    context 'when crm_v2 feature flag is disabled' do
      it 'returns contacts with email, phone_number, or identifier using feature flag value' do
        # Create contacts with different attributes
        contact_with_email = create(:contact, account: account, email: 'test@example.com', name: 'John Doe')
        contact_with_phone = create(:contact, account: account, phone_number: '+1234567890', name: 'Jane Smith')
        contact_with_identifier = create(:contact, account: account, identifier: 'user123', name: 'Bob Wilson')
        contact_without_details = create(:contact, account: account, name: 'Alice Johnson', email: nil, phone_number: nil, identifier: nil)

        resolved = account.contacts.resolved_contacts(use_crm_v2: false)

        expect(resolved).to include(contact_with_email, contact_with_phone, contact_with_identifier)
        expect(resolved).not_to include(contact_without_details)
      end
    end

    context 'when crm_v2 feature flag is enabled' do
      it 'returns only contacts with contact_type lead' do
        # Contact with email and phone - should be marked as lead
        contact_with_details = create(:contact, account: account, email: 'customer@example.com', phone_number: '+1234567890', name: 'Customer One')
        expect(contact_with_details.contact_type).to eq('lead')

        # Contact without email/phone - should be marked as visitor
        contact_without_details = create(:contact, account: account, name: 'Lead', email: nil, phone_number: nil)
        expect(contact_without_details.contact_type).to eq('visitor')

        # Force set contact_type to lead for testing
        contact_without_details.update!(contact_type: 'lead')

        resolved = account.contacts.resolved_contacts(use_crm_v2: true)

        expect(resolved).to include(contact_with_details)
        expect(resolved).to include(contact_without_details)
      end

      it 'includes all lead contacts regardless of email/phone presence' do
        # Create a lead contact with only name
        lead_contact = create(:contact, account: account, name: 'Test Lead')
        lead_contact.update!(contact_type: 'lead')

        # Create a customer contact
        customer_contact = create(:contact, account: account, email: 'customer@test.com')
        customer_contact.update!(contact_type: 'customer')

        # Create a visitor contact
        visitor_contact = create(:contact, account: account, name: 'Visitor')
        expect(visitor_contact.contact_type).to eq('visitor')

        resolved = account.contacts.resolved_contacts(use_crm_v2: true)

        expect(resolved).to include(lead_contact)
        expect(resolved).not_to include(customer_contact)
        expect(resolved).not_to include(visitor_contact)
      end

      it 'returns contacts with email, phone_number, or identifier when explicitly passing use_crm_v2: false' do
        # Even though feature flag is enabled, we're explicitly passing false
        contact_with_email = create(:contact, account: account, email: 'test@example.com', name: 'John Doe')
        contact_with_phone = create(:contact, account: account, phone_number: '+1234567890', name: 'Jane Smith')
        contact_without_details = create(:contact, account: account, name: 'Alice Johnson', email: nil, phone_number: nil, identifier: nil)

        resolved = account.contacts.resolved_contacts(use_crm_v2: false)

        # Should use the old logic despite feature flag being enabled
        expect(resolved).to include(contact_with_email, contact_with_phone)
        expect(resolved).not_to include(contact_without_details)
      end
    end

    context 'with mixed contact types' do
      it 'correctly filters based on use_crm_v2 parameter regardless of feature flag' do
        # Create different types of contacts
        visitor_contact = create(:contact, account: account, name: 'Visitor')
        lead_with_email = create(:contact, account: account, email: 'lead@example.com', name: 'Lead')
        lead_without_email = create(:contact, account: account, name: 'Lead Only')
        lead_without_email.update!(contact_type: 'lead')
        customer_contact = create(:contact, account: account, email: 'customer@example.com', name: 'Customer')
        customer_contact.update!(contact_type: 'customer')

        # Test with use_crm_v2: false
        resolved_old = account.contacts.resolved_contacts(use_crm_v2: false)
        expect(resolved_old).to include(lead_with_email, customer_contact)
        expect(resolved_old).not_to include(visitor_contact, lead_without_email)

        # Test with use_crm_v2: true
        resolved_new = account.contacts.resolved_contacts(use_crm_v2: true)
        expect(resolved_new).to include(lead_with_email, lead_without_email)
        expect(resolved_new).not_to include(visitor_contact, customer_contact)
      end
    end
  end
end
