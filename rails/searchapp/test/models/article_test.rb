# == Schema Information
#
# Table name: articles
#
#  id           :integer          not null, primary key
#  title        :string
#  content      :text
#  published_on :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  abstract     :text
#  url          :string
#  shares       :integer
#

require 'test_helper'

class ArticleTest < ActiveSupport::TestCase
  teardown do
    Article.__elasticsearch__.unstub(:search)
  end


  
  test "has a search method delegating to __elasticsearch__" do
    Article.__elasticsearch__.expects(:search).with do |definition|
      assert_equal 'foo', definition.to_hash[:query][:bool][:should][0][:multi_match][:query]
      true
    end

    Article.search 'foo'
  end

end
