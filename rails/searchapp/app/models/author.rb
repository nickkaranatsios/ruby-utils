# == Schema Information
#
# Table name: authors
#
#  id         :integer          not null, primary key
#  first_name :string
#  last_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Author < ActiveRecord::Base
  has_many :authorships

  def full_name
    [first_name, last_name].join(' ')
  end
end
