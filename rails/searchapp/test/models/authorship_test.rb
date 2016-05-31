# == Schema Information
#
# Table name: authorships
#
#  id         :integer          not null, primary key
#  article_id :integer
#  author_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class AuthorshipTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
