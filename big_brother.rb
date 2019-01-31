require 'aws-record'
require 'faraday'
require 'faraday-cookie_jar'
require 'rehtml'

class Assignment
  include Aws::Record
  set_table_name ENV['DDB_TABLE']
  string_attr :hash, hash_key: true
  string_attr :course_title
  string_attr :name
  integer_attr :percentage

  def hash
    [
      self.course_title,
      self.name,
      self.percentage
    ]
    .join
    .gsub(/[[:space:]]/, '')
  end

  def save
    self.hash = self.hash
    super
  end
end

def entry(event:, context:)
  old_assignment_hashes = Assignment.scan.map(&:hash)

  new_assignments = current_assignments
  .uniq { |assignment| assignment.hash }
  .reject { |assignment| old_assignment_hashes.include?(assignment.hash) }

  new_assignments.each { |assignment| assignment.save }

  if new_assignments.count > 0
    ENV['RECIPIENTS'].split(',').each do |recipient|
      send_sms(recipient, aggregate_report(new_assignments))
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

def aggregate_report(new_assignments)
  lines = new_assignments.map do |assignment|
    "#{assignment.percentage}% on #{assignment.name} in #{assignment.course_title}"
  end
  ["New grades for Danoel:"].concat(lines).join("\n\n")
end

def current_assignments
  grade_site = Faraday.new(url: 'https://hac40.esp.k12.ar.us') do |faraday|
    faraday.request(:url_encoded)
    faraday.response(:logger)
    faraday.use(:cookie_jar)
    faraday.adapter(Faraday.default_adapter)
  end

  # Initial post to authenticate.
  grade_site.post('/HomeAccess40/Account/LogOn?ReturnUrl=%2fHomeAccess40%2f', {
    'Database' => ENV['SCHOOL_ID'],
    'LogOnDetails.UserName' => ENV['SCHOOL_USERNAME'],
    'LogOnDetails.Password' => ENV['SCHOOL_PASSWORD']
  })

  # The assignments are displayed within an IFrame.
  # A GET directly on the src URL of that IFrame returns a 302 unless a GET
  # is first made for the URL that contains that IFrame.
  grade_site.get('/HomeAccess40/Classes/Classwork')
  old_assignments_doc = REHTML.to_rexml(
    grade_site.get('/HomeAccess40/Content/Student/Assignments.aspx').body
  )

  # Now we have the assignments, but by default the site displays only outdated
  # assignments for the first semester. These outdated assignments are displayed
  # within a form that includes a dropdown option that supports switching the
  # view to display all assignments. Since this is a legacy ASP.net weform, it
  # expects a postback to its URL that includes special viewstate params. The
  # values it expects for those params are the values that it rendered on the
  # previous request. The event target param is the value of the dropdown option.
  view_state = old_assignments_doc.elements['html/body/div[@id="MainContent"]/div[@class="sg-hac-content"]/form/input[@name="__VIEWSTATE"]'].attributes['value']

  view_state_generator = old_assignments_doc.elements['html/body/div[@id="MainContent"]/div[@class="sg-hac-content"]/form/input[@name="__VIEWSTATEGENERATOR"]'].attributes['value']

  event_validation = old_assignments_doc.elements['html/body/div[@id="MainContent"]/div[@class="sg-hac-content"]/form/input[@name="__EVENTVALIDATION"]'].attributes['value']

  view_state_params = {
    '__VIEWSTATE' => view_state,
    '__EVENTTARGET' => 'ctl00$plnMain$btnRefreshView',
    '__VIEWSTATEGENERATOR' => view_state_generator,
    '__EVENTVALIDATION' => event_validation,
  }
  all_assignments_doc = REHTML.to_rexml(
    grade_site.post('/HomeAccess40/Content/Student/Assignments.aspx', view_state_params).body
  )

  assignments = []

  courses = all_assignments_doc
    .elements
    .to_a('html/body/div[@id="MainContent"]/div[@class="sg-hac-content"]/form/div[@class="sg-content-grid"]/div[@class="AssignmentClass"]')

  courses.each do |course|
    course_title = course
      .elements['div[@class="sg-header sg-header-square"]/a[@class="sg-header-heading"]']
      .first
      .to_s
      .gsub(/[^a-z]/i, '')
    course_assignments = course
      .elements
      .to_a('div[@class="sg-content-grid"]/table/tr[@class="sg-asp-table-data-row"]')

    course_assignments.each do |course_assignment|
      cells = course_assignment.elements.to_a('td')
      name = cells[2].elements['a'][0].to_s.strip
      raw_percentage = cells[9][0].to_s
      percentage = raw_percentage.strip.empty? ? nil : raw_percentage.to_i

      assignments.push(Assignment.new(
        course_title: course_title,
        name: name,
        percentage: percentage
      ))
    end
  end

  assignments
end
