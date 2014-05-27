require "pp"

class Port
  attr_accessor :id, :slice

  def initialize id, slice
    @id, @slice = id, slice
  end
end

d = []
(1..5).each do | n |
  d << Port.new( n, 100 )
end
(6..8).each do | n |
  d << Port.new( n, 200 )
end
(9..12).each do | n |
  d << Port.new( n, 300 )
end

h = d.group_by do | e |
  e.slice
end
pp h
