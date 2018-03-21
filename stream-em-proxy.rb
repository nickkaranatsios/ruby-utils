require 'em-http'
require 'json'
require 'pp'




module FrameInHandler
  def post_init
    @packet_in = ""
    @line_count = 0
  end

  def receive_data data
    puts "size of data #{data.length}"
    @packet_in << data
    pp data
  end
end

host,port = "localhost", 5555
EM.error_handler do |e|
  puts "catch EM error and ignore"
end
EM.run do
  Signal.trap("INT") { EventMachine.stop }
	Signal.trap("TERM") { EventMachine.stop }
  EM.start_server(host, port, FrameInHandler)
end
