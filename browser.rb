require 'em-http'
require 'faye/websocket'
require 'json'
require 'pp'

EM.run do
  conn = EM::HttpRequest.new('http://localhost:9222/json').get
  conn.callback do
    resp = JSON.parse(conn.response)
    puts "#{resp.size} available tabs Chrome response"
    pp resp

    ws = Faye::WebSocket::Client.new('WebSocketDebuggerUrl')
    ws.on :open do |event|
      ws.send JSON.dump({id: 1, method: 'Network.enable'})
puts "ws network enable"
      ws.send JSON.dump({
        id: 2,
        method: 'Page.navigate',
        params: {url: 'http://twitter.com/#!/search/chrome?q=chrome&' + rand(100).to_s},
      })
    end
    ws.on :message do |event|
      p [:new_message, JSON.parse(event.data)]
    end
    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end
  end
end
