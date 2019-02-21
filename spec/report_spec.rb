require 'rspec'
require_relative '../report'

RSpec.describe Report do
  describe "#message" do
    it "returns its assignments in a nicely formatted string" do
      assignments = [
        Assignment.new(
          course_title: 'Geometry',
          name: 'Test',
          percentage: 50
        ),
        Assignment.new(
          course_title: 'History',
          name: 'Homework',
          percentage: 100
        )
      ]

      message = described_class.new(assignments).message

      expect(message).to eq(<<~MESSAGE.chomp)
        New grades for Danoel:

        50% on Test in Geometry

        100% on Homework in History
      MESSAGE
    end
  end
end
