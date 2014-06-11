class Packet
  attr_accessor :dpid, :in_port
  def initialize dpid, in_port
    @dpid, @in_port = dpid, in_port
  end
end

class Link
  attr_accessor :dpid, :port
  def initialize dpid, packet
    @dpid, @port = dpid, packet.in_port
  end

  def <=>other
    @dpid <=> other.dpid && @port <=> other.port
  end
end
