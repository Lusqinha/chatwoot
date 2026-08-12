require 'rails_helper'

RSpec.describe Contacts::PhoneVariantBuilders::Brazil do
  subject(:builder) { described_class.new }

  describe '#handles?' do
    it 'handles Brazilian E.164 numbers' do
      expect(builder).to be_handles('+5541999998888')
    end

    it 'does not handle numbers from other countries' do
      aggregate_failures do
        expect(builder).not_to be_handles('+12025550123')
        expect(builder).not_to be_handles('+541155551234')
      end
    end
  end

  describe '#variants' do
    context 'with a mobile carrying the ninth digit (13 digits)' do
      it 'returns the equivalent without the ninth digit' do
        expect(builder.variants('+5541999998888')).to eq(['+554199998888'])
      end
    end

    context 'with a mobile missing the ninth digit (12 digits)' do
      it 'returns the equivalent with the ninth digit' do
        expect(builder.variants('+554199998888')).to eq(['+5541999998888'])
      end
    end

    context 'with a subscriber at the mobile boundary (first digit 6-9)' do
      it 'treats the whole 6-9 range as mobile' do
        aggregate_failures do
          expect(builder.variants('+554166667777')).to eq(['+5541966667777'])
          expect(builder.variants('+554199998888')).to eq(['+5541999998888'])
        end
      end
    end

    context 'with a landline (subscriber starting 2-5)' do
      it 'returns no variant so landlines are never merged with mobiles' do
        aggregate_failures do
          expect(builder.variants('+554122223333')).to eq([])
          expect(builder.variants('+554133334444')).to eq([])
          expect(builder.variants('+554155556666')).to eq([])
        end
      end
    end

    context 'with a 13-digit number whose post-9 digit is not a mobile prefix' do
      it 'returns no variant to avoid colliding with a landline' do
        expect(builder.variants('+5541933334444')).to eq([])
      end
    end
  end
end
