require 'em-websocket-client'
EM.run do
  conn = EventMachine::WebSocketClient.new("ws://localhost:9999") do 
    conn.callback do 
      conn.send_msg "Hello"
      conn.send_msg "ddne"
    end

    conn.errback do |e|
      puts "web socket error #{e}"
    end

    conn.stream do |msg|
      puts "#{msg}"
      if msg.data == "done"
        conn.close_connection
      end
    end

    conn.disconnect do
      puts "gone"
      EM::stop_event_loop
    end
  end
end
