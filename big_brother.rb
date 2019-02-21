require_relative 'assignment'
require_relative 'school_website'
require_relative 'report'
require_relative 'twilio_client'

def entry(event:, context:)
  old_assignment_hashes = Assignment.scan.map(&:hash)

  new_assignments = SchoolWebsite.assignments
  .uniq { |assignment| assignment.hash }
  .reject { |assignment| old_assignment_hashes.include?(assignment.hash) }

  new_assignments.each { |assignment| assignment.save }

  if new_assignments.count > 0
    message = Report.new(new_assignments).message
    twilio_client = TwilioClient.new

    ENV['RECIPIENTS'].split(',').each do |recipient|
      twilio_client.send_sms(recipient, message)
    end
  end
end
