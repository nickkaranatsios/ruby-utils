require "active_model"
require "yajl"

class User 
  include ActiveModel::Serializers::JSON
  attr_reader :name, :age, :active

  def initialize(name, age, active = true)
    @name = name
    @age = age
    @active = active
  end

  # this is required for it to work
  def attributes
    { 'name' => nil, 'age' => nil, 'active' => nil }
  end

  def capitalize_name
    name.capitalize
  end
end

u = User.new("me", 47)
#puts u.serializable_hash(only: 'age')
#puts u.serializable_hash(methods: 'capitalize_name')
#puts u.to_json(only: 'age')
#all object attributes
#puts u.to_json

# or can use the yajl as
puts Yajl::Encoder.encode(u.serializable_hash(methods:'capitalize_name'))
