# == Schema Information
#
# Table name: comments
#
#  id            :integer          not null, primary key
#  body          :text
#  user          :string
#  user_location :string
#  stars         :integer
#  pick          :boolean
#  article_id    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end