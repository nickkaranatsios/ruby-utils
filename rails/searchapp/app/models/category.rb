# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Category < ActiveRecord::Base
  include Elasticsearch::Model
  has_and_belongs_to_many :articles

  index_name [Rails.application.engine_name, Rails.env].join('_')

  settings do
    mapping do
      indexes :title, analyzer: 'simple'
    end
  end

    # Customize the JSON serialization for Elasticsearch
  #
  def as_indexed_json(options={})
    as_json(only: 'title')
  end
end
