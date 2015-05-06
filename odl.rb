require 'em-http'
require 'faye/websocket'
require 'json'
require 'pp'


def nodes_url
  "opendaylight-inventory:nodes"
end


class NodeParser
  def self.parse response, nodes
    data = JSON.parse(response)
    id = data['nodes']['node'][0]['id'].split(':')[1].to_i
    if nodes[id].nil?
      nodes[id] = {"ports" => [], "flows" => []}
    end
    nodes_arr = data['nodes']['node']
    nodes_arr.each do |node|
      puts node['id'] if node['id'] =~ /^openflow/
      ncs = node['node-connector']
      if not ncs.nil? 
        ncs.each do |nc|
          nodes[id]['ports'] << {nc['id'] => nc['opendaylight-port-statistics:flow-capable-node-connector-statistics']}
        end
      end
      fns = node['flow-node-inventory:table']
      if not fns.nil?
        fns.each do |fn|
          nodes[id]['flows'] << {fn['id'] => Array.new.push(fn['opendaylight-flow-table-statistics:flow-table-statistics'],fn['opendaylight-flow-statistics:aggregate-flow-statistics'])}
        end
      end
    end
    #pp nodes[id]['flows'].sort_by {|a| a.keys[0]}
  end

  def for_each_node data
    data['node'].each do |node|
      yield node['node-connector'], node['flow-node-inventory:table'] if block_given?
    end
  end
end


module PacketInHandler
  def post_init
    @packet_in = ""
    @line_count = 0
  end

  def receive_data data
    puts data.class
    @packet_in << data
    pp data
  end
end

nodes = []
base_url = "http://remote-host:8080/restconf/operational"
host,port = "localhost", 5555
EM.error_handler do |e|
  puts "catch EM error and ignore"
end
EM.run do
#subscription_url = "http://remote-host:8185/opendaylight-inventory:nodes/datastore=CONFIGURATION/scope=BASE"
#  ws = Faye::WebSocket::Client.new(subscription_url)
#  ws.on :message do |event|
#    pp [:new_message, event.data]
#  end
#  ws.on :close do |event|
#    p [:close, event.code, event.reason]
#    ws = nil
#  end
  EM.start_server(host, port, PacketInHandler)
  EM.add_periodic_timer( 5 ) do
    url = "#{base_url}/#{nodes_url}"
    http = EM::HttpRequest.new(url).get
    http.errback do
      puts "error retrieving data from url #{url}"
    end

    http.callback do
      if http.response_header.status == 200
        pp http.response_header
        NodeParser.parse http.response, nodes
      else
        pp http.response_header.status
      end
    end
  end
end
