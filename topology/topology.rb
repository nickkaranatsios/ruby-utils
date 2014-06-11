require "pp"
require_relative "port"
require_relative "link"

class Topology
  def initialize
    @ports = Hash.new { [].freeze }
    @links = []
    @dist = {}
    @pred = {}
  end

  def add_port port
    @ports[ port.dpid ] += [ port ]
  end

  def delete_port port
    @ports[ port.dpid ] -= [ port ]
  end

  def add_link dpid, pin
    link = Link.new( dpid, pin )
    @links << link unless @links.include? link
    @links.sort!
  end

  def to_external? dpid, port
    link = @links.find { | l | l.dpid == dpid and l.port == port }
puts "link = #{ link.inspect }"
    link.nil? ? true: false
  end
end

t = Topology.new
p1_1 = Port.new( 1, 1 )
p1_2 = Port.new( 1, 2 )
p1_3 = Port.new( 1, 3 )

p2_1 = Port.new( 2, 1 )
p2_2 = Port.new( 2, 2 )
p2_3 = Port.new( 2, 3 )
p2_4 = Port.new( 2, 4 )

p3_1 = Port.new( 3, 1 )
p3_2 = Port.new( 3, 2 )
p3_3 = Port.new( 3, 3 )
p3_4 = Port.new( 3, 4 )

p4_1 = Port.new( 4, 1 )
p4_2 = Port.new( 4, 2 )
p4_3 = Port.new( 4, 3 )
p4_4 = Port.new( 4, 4 )

p5_1 = Port.new( 5, 1 )
p5_2 = Port.new( 5, 2 )
p5_3 = Port.new( 5, 3 )
p5_4 = Port.new( 5, 4 )

p6_1 = Port.new( 6, 1 )
p6_2 = Port.new( 6, 2 )
p6_3 = Port.new( 6, 3 )
t.add_port p1_1 
t.add_port p1_2 
t.add_port p1_3 

t.add_port p2_1
t.add_port p2_2
t.add_port p2_3
t.add_port p2_4

t.add_port p3_1
t.add_port p3_2
t.add_port p3_3
t.add_port p3_4

t.add_port p4_1
t.add_port p4_2
t.add_port p4_3
t.add_port p4_4

t.add_port p5_1
t.add_port p5_2
t.add_port p5_3
t.add_port p5_4

t.add_port p6_1
t.add_port p6_2
t.add_port p6_3


pin = Packet.new( 1, 1 )
t.add_link 1, pin 
pin = Packet.new( 1, 2 )
t.add_link 1, pin 

pin = Packet.new( 2, 1 )
t.add_link 2, pin
pin = Packet.new( 2, 2 )
t.add_link 2, pin
pin = Packet.new( 2, 3 )
t.add_link 2, pin
pin = Packet.new( 2, 4 )
t.add_link 2, pin

pin = Packet.new( 3, 1 )
t.add_link 3, pin
pin = Packet.new( 3, 2 )
t.add_link 3, pin
pin = Packet.new( 3, 3 )
t.add_link 3, pin
pin = Packet.new( 3, 4 )
t.add_link 3, pin

pin = Packet.new( 4, 1 )
t.add_link 4, pin
pin = Packet.new( 4, 2 )
t.add_link 4, pin
pin = Packet.new( 4, 3 )
t.add_link 4, pin
pin = Packet.new( 4, 4 )
t.add_link 4, pin

pin = Packet.new( 5, 1 )
t.add_link 5, pin
pin = Packet.new( 5, 2 )
t.add_link 5, pin
pin = Packet.new( 5, 3 )
t.add_link 5, pin
pin = Packet.new( 5, 4 )
t.add_link 5, pin

#pp t

puts t.to_external?( 1, 1 )
