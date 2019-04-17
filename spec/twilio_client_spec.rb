require 'webmock/rspec'
require_relative 'spec_helper'
require_relative '../lib/twilio_client'

RSpec.describe TwilioClient do
  describe "#send_sms" do
    it "posts the right params to the Twilio create message endpoint" do
      recipient = '5018675309'
      message = 'super cool message'
      full_endpoint_url = described_class::URL + described_class::CREATE_MESSAGE_ENDPOINT
      stub_request(:post, full_endpoint_url)

      described_class.new.send_sms(recipient, message)

      expect(a_request(:post, full_endpoint_url).with(
        body: {
          Body: message,
          From: described_class::FROM,
          To: recipient
        }
      )).to have_been_made.once
    end
  end
end
