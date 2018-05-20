require 'pp'

# this test program contains extensions about how to use refinements.
# one caveat worth noting is that to_proc doesn't work with refinements.
module ListStrings
	refine String do
		def +(other)
			"#{self}, #{other}"
		end
	end
end

using ListStrings
puts "4" + "5"

module Foo
	refine Integer do
		def to_s
			:foo
		end
	end
end

class NumAsString
	def num(input)
		input.to_s
	end
end

class NumAsFoo
	using Foo
	def num(input)
		input.to_s
	end
end

puts NumAsString.new.num(4)
puts NumAsFoo.new.num(4)

module Moo
	refine Integer do
		def to_s
			"moo"
		end
	end
end

class A
	using Moo

	def a
		[1,2,3].map {|x| x.to_s}
	end

	def b
		[1,2,3].map(&:to_s)
	end
end

puts A.new.a
puts "b moo"
puts A.new.b

module Baz
	refine String do
		def baz
			:baz
		end
	end
end

class Venue
	using Baz
	def respond?
		"".respond_to? :baz
	end

	def call
		"".baz
	end
end

puts Venue.new.respond?

puts Venue.new.call
	



module Extensions
	refine Symbol do
  	def first
  		"#{self}.first"
  	end
  
  	def last
  		"#{self}.last"
  	end
  
  	def [](range)
  		"#{self}.[#{range.first},#{range.last}]"
  	end
  
  	def select(equality)
  		"#{self}.select(#{equality})"
  	end
  end
  
# to_proc with refinements doesn't work
#	refine Integer do
#  	def to_proc
#  		Proc.new do |obj, *args|
#  			puts "self is #{self}"
#  			obj % self == 0
#  		end
#  	end
#  end
#  
#  refine Hash do
#  	def to_proc
#  		Proc.new do |obj, *args|
#  			res =  self.select { |k, v| k == obj.keys.first && v == obj.values.first}
#  			res.empty? ? nil : obj
#  		end
#  	end
#  end
end

module CoreRefinements
	refine Hash do
  	def match(obj)
			puts "refine hash #{self}"
  		res =  self.select { |k, v| k == obj.keys.first && v == obj.values.first}
  		res.empty? ? nil : obj
  	end
  end

	refine Integer do
  	def mod(num)
  		puts "self is #{self}"
  		self % num == 0
  	end
	end

	refine Array do
		def match(obj)
			puts "self array is #{self}"
			self == obj
		end
	end
end

using CoreRefinements
# [{"0"=>0, "1"=>1}, {"1"=>3, "2"=>4}, {"2"=>6, "3"=>7}, {"3"=>9, "4"=>10}]
# [{"0"=>0}, {"1"=>3}, {"2"=>6}, {"3"=>9}]
ha = Array.new(4) { |x| Hash[x.to_s, x * 3, (x + 1).to_s, x * 3 + 1] }
pp ha
puts ha.select {|h| h.match("1" => 3)}

a = Array.new(5) {|x| x ** 2 }
pp a
pp a.select {|e| e.mod(3)}

using Extensions
s = :any_symbol[0..3]
s = :any_symbol.select(4)

res_id, access_key = s.split('.', 2)
if access_key.match?(/^\[/)
	m = access_key.match(/^\[(.*)\]/)
	if m[1]
		low, high = m[1].split(',').map(&:to_i)		
		puts "access result is #{a.send(:[], low, high)}"
	end
elsif access_key.match?(/^select/)
	m = access_key.match(/^select\((.*)\)/)
	puts "equality == #{m[1]}"
	output = a.select {|e| e == m[1].to_i}
	puts "access result is #{output}"
else
	puts "access result is #{a.send(access_key)}"
end
