require "pp"
require "pio"
require "forwardable"

require_relative "port"
require_relative "link"

class Topology
  extend Forwardable
  def_delegator :@ports, :each_pair, :each_switch

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

  def link_between from_dpid, to_dpid
    @links.find { | l | l.from_dpid == from_dpid && l.to_dpid == to_dpid }
  end

  def to_external? dpid, port
    link = @links.find { | l | l.dpid == dpid and l.port == port }
    link.nil? ? true: false
  end

  def build_path
    @dist.clear
    @pred.clear
    each_switch do | dpid_1, ports_1 |
      @dist[ dpid_1 ] = {}
      @pred[ dpid_1 ] = {}
      each_switch do | dpid_2, ports_2 |
        link = link_between( dpid_1, dpid_2 )
        if link 
          @dist[ dpid_1 ][ dpid_2 ] = 1
          @pred[ dpid_1 ][ dpid_2 ] = dpid_1
        else
          @dist[ dpid_1 ][ dpid_2 ] = 99999
          @pred[ dpid_1 ][ dpid_2 ] = nil
        end
        @dist[ dpid_1 ][ dpid_1 ] = 0
      end
    end
    each_switch do | dpid_t, ports_t |
      each_switch do | dpid_1, ports_1 |
        each_switch do | dpid_2, ports_2 |
          link_cost = @dist[ dpid_1 ][ dpid_t ] + @dist[ dpid_t ][ dpid_2 ]
          if link_cost < @dist[ dpid_1 ][ dpid_2 ]
            @dist[ dpid_1 ][ dpid_2 ] = link_cost
            @pred[ dpid_1 ][ dpid_2 ] = @pred[ dpid_t ][ dpid_2 ]
          end
        end
      end
    end
    #pp @dist
    pp @pred
  end  

  def path_between start, goal
puts "pred start = #{ @pred[ start ] }"
    start == goal ? nil: @pred[ start ]
  end
  
  def resolve_path from_dpid, from_port, to_dpid, to_port
    hops = []
    in_port = from_port
    current_dpid = from_dpid
    pred = path_between( to_dpid, from_dpid )
    if pred
      while pred[ current_dpid ]
        next_dpid = pred[ current_dpid ]
puts "cur dpid #{ current_dpid } next dpid #{ next_dpid }"
        link = link_between( current_dpid, next_dpid )
        if link
          hop = {}
          hop[ :dpid ] = current_dpid.to_s
          hop[ :in_port ] = in_port
          current_dpid = next_dpid
          hop[ :out_port ] = link.from_port
          in_port = link.to_port
          hops << hop
        else
        end
      end
    end
    hop = {}
    hop[ :dpid ] = current_dpid.to_s
    hop[ :in_port ] = in_port
    hop[ :out_port ] = to_port
    hops << hop
    puts "hops: "
    pp hops
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


pin = Packet.new( 2, 2, Pio::Lldp.new( dpid: 1, port_number: 2 ) )
t.add_link 2, pin 

pin = Packet.new( 3, 4, Pio::Lldp.new( dpid: 1, port_number: 3 ) )
t.add_link 3, pin 

pin = Packet.new( 3, 2, Pio::Lldp.new( dpid: 2, port_number: 3 ) )
t.add_link 3, pin

pin = Packet.new( 1, 2, Pio::Lldp.new( dpid: 2, port_number: 2 ) )
t.add_link 1, pin

pin = Packet.new( 4, 4, Pio::Lldp.new( dpid: 2, port_number: 4 ) )
t.add_link 4, pin

pin = Packet.new( 2, 3, Pio::Lldp.new( dpid: 3, port_number: 2 ) )
t.add_link 2, pin

pin = Packet.new( 1, 3, Pio::Lldp.new( dpid: 3, port_number: 4 ) )
t.add_link 1, pin

pin = Packet.new( 5, 2, Pio::Lldp.new( dpid: 2, port_number: 1 ) )
t.add_link 5, pin

pin = Packet.new( 5, 3, Pio::Lldp.new( dpid: 3, port_number: 3 ) )
t.add_link 5, pin

pin = Packet.new( 3, 1, Pio::Lldp.new( dpid: 4, port_number: 3 ) )
t.add_link 3, pin


pin = Packet.new( 5, 4, Pio::Lldp.new( dpid: 4, port_number: 2 ) )
t.add_link 5, pin

pin = Packet.new( 2, 4, Pio::Lldp.new( dpid: 4, port_number: 4 ) )
t.add_link 2, pin

pin = Packet.new( 3, 3, Pio::Lldp.new( dpid: 5, port_number: 3 ) )
t.add_link 3, pin

pin = Packet.new( 2, 1, Pio::Lldp.new( dpid: 5, port_number: 2 ) )
t.add_link 2, pin

pin = Packet.new( 6, 3, Pio::Lldp.new( dpid: 4, port_number: 1 ) )
t.add_link 6, pin

pin = Packet.new( 4, 3, Pio::Lldp.new( dpid: 3, port_number: 1 ) )
t.add_link 4, pin

pin = Packet.new( 4, 1, Pio::Lldp.new( dpid: 6, port_number: 3 ) )
t.add_link 4, pin

pin = Packet.new( 4, 2, Pio::Lldp.new( dpid: 5, port_number: 4 ) )
t.add_link 4, pin

pin = Packet.new( 5, 1, Pio::Lldp.new( dpid: 6, port_number: 2 ) )
t.add_link 5, pin

pin = Packet.new( 6, 2, Pio::Lldp.new( dpid: 5, port_number: 1 ) )
t.add_link 6, pin

#pp t

t.link_between 1, 3
t.build_path
t.resolve_path 1, 1, 6, 1

#puts t.to_external?( 1, 1 )
