require 'rspec'
require_relative '../assignment'

RSpec.describe Assignment do
  describe '#hash' do
    it 'returns a custom hash' do
      hash = described_class.new(
        course_title: 'Physical Education',
        name: 'Pushup Challenge',
        percentage: 85
      ).hash

      expect(hash).to eq('PhysicalEducationPushupChallenge85')
    end
  end
end
