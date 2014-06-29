require "em-hiredis"
require "yajl"
require "pp"

class PubSubClient
  def initialize
    @redis = EM::Hiredis.connect
  end

  def subscribe
    puts "Subscribing"
    @redis.pubsub.subscribe( 'command' ) do | msg |
      puts msg
    end
  end

  def publish( message )
    @redis.publish( 'command', encode_json( message ) )
  end

  def unsubscribe
    @redis.pubsub.unsubscribe( 'command' )
  end

  def encode_json( obj )
    Yajl::Encoder.encode( obj )
  end
end

EM.run do
  ps = PubSubClient.new
  ps.subscribe

  EM.add_periodic_timer( 1 ) do
    ps.publish( { :cmd => :start, :sub_cmd => :object, :options => "read this file" } )
  end

  EM.add_timer( 20 ) do
    ps.unsubscribe
    EM.stop
  end
end
