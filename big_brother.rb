require 'faraday'
require 'faraday-cookie_jar'
require_relative 'assignment'
require_relative 'school_website'
require_relative 'report'

def entry(event:, context:)
  old_assignment_hashes = Assignment.scan.map(&:hash)

  new_assignments = SchoolWebsite.assignments
  .uniq { |assignment| assignment.hash }
  .reject { |assignment| old_assignment_hashes.include?(assignment.hash) }

  new_assignments.each { |assignment| assignment.save }

  if new_assignments.count > 0
    message = Report.new(new_assignments).message

    ENV['RECIPIENTS'].split(',').each do |recipient|
      send_sms(recipient, message)
    end
  end
end

def send_sms(recipient, message)
  twilio_api = Faraday.new(url: 'https://api.twilio.com/') do |faraday|
    faraday.request(:url_encoded)
    faraday.response(:logger)
    faraday.adapter(Faraday.default_adapter)
    faraday.basic_auth(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end

  twilio_api.post('/2010-04-01/Accounts/AC45e490df21d67d5214b7faab4597f4d2/Messages.json', {
      'Body' => message,
      'From' => '+15012224183',
      'To' => recipient
  })
end
