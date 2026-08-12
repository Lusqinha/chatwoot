require 'rails_helper'

RSpec.describe Contacts::PhoneNumberVariants do
  describe '#all' do
    it 'always includes the number itself' do
      expect(described_class.new('+5541999998888').all).to include('+5541999998888')
    end

    it 'returns both ninth-digit forms for a Brazilian mobile' do
      aggregate_failures do
        expect(described_class.new('+554199998888').all).to contain_exactly('+554199998888', '+5541999998888')
        expect(described_class.new('+5541999998888').all).to contain_exactly('+5541999998888', '+554199998888')
      end
    end

    it 'returns only the number for a Brazilian landline' do
      expect(described_class.new('+554133334444').all).to eq(['+554133334444'])
    end

    it 'returns only the number for other countries' do
      expect(described_class.new('+12025550123').all).to eq(['+12025550123'])
    end

    it 'does not treat a different DDD as the same line' do
      expect(described_class.new('+5541999998888').all).not_to include('+5511999998888')
    end

    context 'when the number is blank' do
      it 'returns the value unchanged without raising' do
        aggregate_failures do
          expect(described_class.new(nil).all).to eq([nil])
          expect(described_class.new('').all).to eq([''])
        end
      end
    end
  end
end
