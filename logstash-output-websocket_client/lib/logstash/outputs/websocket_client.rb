# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "socket"
require "ftw"

# An example output that does nothing.
class LogStash::Outputs::WebsocketClient < LogStash::Outputs::Base
  config_name "websocket_client"

	default :codec, "json"
	config :url, validate: :string, required: true
	config :mode, validate: ["client"], default: "client"

  public
  def register
		agent = FTW::Agent.new
		@websocket = agent.websocket!(@url)
  end # def register

  public
  def receive(event)
		@websocket.publish(event.to_json)
  end # def event
end # class LogStash::Outputs::Websocket_client
