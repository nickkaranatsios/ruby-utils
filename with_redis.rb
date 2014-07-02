require "redis"
require "pp"


#https://practicingruby.com/articles/attacking-sticky-problems
data       = ["6/14/2011", "2", "36.00", "-1.69", "34.31"]
names      = ["Date", "Payments Received", "Amount Received", 
                  "Payment Fees", "Net Amount"] 

tbl = Hash[names.zip(data)]
pp tbl
exit

class RedisClient
  def initialize
    @redis = Redis.new
  end

  def with_redis( &blk )
    if @redis && block_given?
      @redis.instance_eval &blk
    end
  end
end

r = RedisClient.new

r.with_redis do
  del( "foo" )
  set( "foo", "bar" )
  puts "the foo keys is set to #{ get( "foo" ) }"
end
