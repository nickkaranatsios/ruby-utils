require "json"
require "bson"
require "pp"

f = File.read("/bin/ls")
f = "euro sign \u20ac one more sign \u20ac \x20"
puts f
result = ""
f.each_byte do |b|
  if b >= 128
    result << sprintf('%x', b)
  else
    result << b.chr
  end
end
h = {}
h[:test] = result
# JSON.generate tries to convert the data to UTF-8.
class User
  attr_accessor :name
  def initialize(name)
    @name = name
  end
end
arr = [BSON::Document.new(name: "nick"), BSON::Document.new(name: "foo", age: 50)]
data = arr.to_bson.to_s

darr = Array.from_bson(BSON::ByteBuffer.new(data))
darr.each {|e| puts e[:name]}
exit


parsed_json = JSON.generate(h)
puts "parsed json = #{parsed_json}"
original = JSON.parse(parsed_json)
org = original["test"]
puts org.bytesize
puts org === result

