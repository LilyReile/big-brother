require_relative 'assignment'

class Report
  def initialize(assignments)
    @assignments = assignments
  end

  def message
    lines = @assignments.map do |a|
      "#{a.percentage}% on #{a.name} in #{a.course_title}"
    end

    ["New grades for Danoel:"].concat(lines).join("\n\n")
  end
end
