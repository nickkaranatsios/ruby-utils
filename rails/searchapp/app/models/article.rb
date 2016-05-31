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

class Article < ActiveRecord::Base
	include Elasticsearch::Model
	include Elasticsearch::Model::Callbacks
  has_and_belongs_to_many :categories, after_add:    [ lambda { |a,c| Indexer.perform_async(:update,  a.class.to_s, a.id) } ],
                                       after_remove: [ lambda { |a,c| Indexer.perform_async(:update,  a.class.to_s, a.id) } ]
  has_many                :authorships
  has_many                :authors, through: :authorships
  has_many                :comments


  include Searchable
end
