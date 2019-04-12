require 'rehtml'
require 'faraday'
require 'faraday-cookie_jar'
require_relative 'assignment'

# This is ugly, but since when is web scraping pretty?
module SchoolWebsite
  def self.assignments
    grade_site = Faraday.new(url: 'https://hac40.esp.k12.ar.us') do |faraday|
      faraday.request(:url_encoded)
      faraday.response(:logger) unless ENV['ENVIRONMENT'] == 'testing'
      faraday.use(:cookie_jar)
      faraday.adapter(Faraday.default_adapter)
    end

    # Initial post to authenticate.
    grade_site.post('/HomeAccess40/Account/LogOn?ReturnUrl=%2fHomeAccess40%2f',
      'Database' => ENV['SCHOOL_ID'],
      'LogOnDetails.UserName' => ENV['SCHOOL_USERNAME'],
      'LogOnDetails.Password' => ENV['SCHOOL_PASSWORD']
    )

    # The assignments are displayed within an IFrame.
    # A GET directly on the src URL of that IFrame returns a 302 unless a GET
    # is first made for the URL that contains that IFrame.
    grade_site.get('/HomeAccess40/Classes/Classwork')
    old_assignments_doc = REHTML.to_rexml(
      grade_site.get('/HomeAccess40/Content/Student/Assignments.aspx').body
    )

    # Now we can see some assignments, but by default the site displays only
    # assignments for the first semester. These are displayed within a form that
    # supports switching to display-all by passing an eventtarget param.
    # Since this is a legacy ASP.net webform, it expects a postback to its URL
    # that includes special viewstate params. The values it expects for those
    # params are the values that it rendered on the previous response.
    all_assignments_params = extract_view_state_params(old_assignments_doc)
      .merge('__EVENTTARGET' => 'ctl00$plnMain$btnRefreshView')

    all_assignments_doc = REHTML.to_rexml(
      grade_site
      .post('/HomeAccess40/Content/Student/Assignments.aspx', all_assignments_params)
      .body
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

      course_assignment_rows = course
        .elements
        .to_a('div[@class="sg-content-grid"]/table/tr[@class="sg-asp-table-data-row"]')

      course_assignment_rows.each do |course_assignment_row|
        cells = course_assignment_row.elements.to_a('td')
        name = cells[2].elements['a'][0].to_s.strip
        raw_percentage = cells[9][0].to_s
        percentage = raw_percentage.strip.empty? ? nil : raw_percentage.to_i

        assignments.push(
          Assignment.new(
            course_title: course_title,
            name: name,
            percentage: percentage
          )
        )
      end
    end

    assignments
  end

  private_class_method def self.extract_view_state_params(document)
    extract_param = ->(param) do
      document
      .elements["html/body/div[@id='MainContent']/div[@class='sg-hac-content']/form/input[@name='__#{param}']"]
      .attributes['value']
    end

    {
      '__VIEWSTATE' => extract_param.call("VIEWSTATE"),
      '__VIEWSTATEGENERATOR' => extract_param.call("VIEWSTATEGENERATOR"),
      '__EVENTVALIDATION' => extract_param.call("EVENTVALIDATION")
    }
  end
end
