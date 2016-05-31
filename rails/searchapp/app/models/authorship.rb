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

class Authorship < ActiveRecord::Base
  belongs_to :article, touch: true

  belongs_to :author
end
