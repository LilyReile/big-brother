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
