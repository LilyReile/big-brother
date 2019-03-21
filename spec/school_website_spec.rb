require 'vcr'
require_relative 'spec_helper'
require_relative '../school_website'

RSpec.describe SchoolWebsite do
  VCR.configure do |config|
    config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
    config.hook_into :webmock
    config.before_record do |cassette|
      cassette.response.body.force_encoding('UTF-8')
    end
  end

  before do
    ENV['SCHOOL_USERNAME'] = ''
    ENV['SCHOOL_PASSWORD'] = ''
    ENV['SCHOOL_ID'] = ''
  end

  describe '.assignments' do
    it 'returns assignments scraped from the school website' do
      VCR.use_cassette("school_website_assignments") do
        assignments = described_class.assignments
        expect(assignments.count).to eq(406)
        expect(assignments.first.hash).to eq('English9WeeksTest73')
      end
    end
  end
end
