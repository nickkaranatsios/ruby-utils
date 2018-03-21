require 'pp'
require 'packetfu'
require 'pcaprub'
require 'bindata'


class AggregateFlow < BinData::Record
  endian :big
  uint8 :version
  uint8 :type
  uint16 :opf_length
  uint32 :transaction_id
  uint16 :subtype
  uint16 :flags
  uint32 :pad
  uint64 :packet_count
  uint64 :byte_count
  uint32 :flow_count
  rest :payload
end
  

i = 0
hash = {}
PacketFu::PcapFile.read("../x.cap") do |pkt|
  packet = PacketFu::Packet.parse(pkt.data)
  pkt_timestamp = pkt.timestamp
  pkt_time_at = Time.at(pkt.timestamp.sec.to_i + (pkt.timestamp.usec.to_i / 1000000.0))
  if pkt_time_at.hour >= 15 && pkt_time_at.min >= 27 && pkt_time.at_min <= 30 
    if packet.is_ip? and packet.is_tcp? 
      if packet.tcp_dst == 6653 && packet.payload.size == 40
        af = AggregateFlow.read(packet.payload)
        if af.version == 0x04 && af.type == 19 && af.subtype == 2
          hash[packet.ip_saddr] = af.flow_count
          puts "Flows from #{packet.ip_saddr} flow_count #{af.flow_count}" if af.flow_count != 0
          if af.flow_count > 1000 
            pp packet
          end
        end
      end
    end
  end
end

pp hash
