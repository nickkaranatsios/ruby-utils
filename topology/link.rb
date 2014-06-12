require "pio"

class Packet
  attr_accessor :dpid, :in_port, :data
  def initialize dpid, in_port, data
    @dpid, @in_port, @data = dpid, in_port, data
  end
end

class Link
  attr_accessor :from_dpid, :from_port, :to_dpid, :to_port
  def initialize to_dpid, pin
    lldp =  pin.data
    @from_dpid, @to_dpid = lldp.dpid, to_dpid
    @from_port, @to_port = lldp.port_id, pin.in_port
  end

  def == other
    @from_dpid == other.from_dpid &&
      @to_dpid == other.to_dpid &&
      @from_port == other.to_port &&
      @to_port == other.to_port
  end

  def <=> other
    to_s <=> other.to_s
  end

  def to_s
    format '%#x (port %d) <-> %#x (port %d)', @from_dpid, @from_port, @to_dpid, @to_port
  end

  def has? dpid, port
    ( @from_dpid == dpid && @from_port == port ) || ( @to_dpid == dpid && @to_port == port )
  end
end
