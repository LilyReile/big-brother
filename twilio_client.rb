require 'faraday'
require 'faraday-cookie_jar'

class TwilioClient
  FROM = '5012224183'
  URL = 'https://api.twilio.com'
  CREATE_MESSAGE_ENDPOINT =
    '/2010-04-01/Accounts/AC45e490df21d67d5214b7faab4597f4d2/Messages.json'

  def initialize
    @client = Faraday.new(url: URL) do |faraday|
      faraday.request(:url_encoded)
      faraday.response(:logger) unless ENV['ENVIRONMENT'] == 'testing'
      faraday.adapter(Faraday.default_adapter)
      faraday.basic_auth(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    end
  end

  def send_sms(recipient, message)
    @client.post(CREATE_MESSAGE_ENDPOINT, {
      Body: message,
      From: FROM,
      To: recipient
    })
  end
end
