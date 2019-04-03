require_relative 'spec_helper'
require_relative '../lib/big_brother'

RSpec.describe 'Big Brother' do
  let(:new_assignment) do
    Assignment.new(course_title: 'Geometry', name: 'Homework', percentage: 0)
  end

  let(:old_assignment) do
    Assignment.new(course_title: 'English', name: 'Test', percentage: 100)
  end

  let(:all_assignments) { [new_assignment, old_assignment] }
  let(:twilio_client_spy) { spy }
  let(:report_spy) { spy }

  before do
    ENV['RECIPIENTS'] = '5017783248,5018675309'
    allow(Assignment).to receive(:scan) { [old_assignment] }
    allow(SchoolWebsite).to receive(:assignments) { all_assignments }
    allow(TwilioClient).to receive(:new) { twilio_client_spy }
    allow(Report).to receive(:new) { report_spy }
    allow(new_assignment).to receive(:save)
  end

  it 'saves new assignments' do
    entry
    expect(new_assignment).to have_received(:save)
  end

  it 'builds a report with new assignments' do
    entry
    expect(Report).to have_received(:new).with(array_including(new_assignment))
  end

  it 'sends an SMS report to each recipient' do
    entry
    expect(twilio_client_spy)
      .to have_received(:send_sms)
      .with('5017783248', report_spy)
    expect(twilio_client_spy)
      .to have_received(:send_sms)
      .with('5018675309', report_spy)
  end

  it 'ignores old assignments' do
    entry
    expect(Report)
      .not_to have_received(:new)
      .with(array_including(old_assignment))
  end
end
