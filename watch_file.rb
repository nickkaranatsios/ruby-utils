require 'eventmachine'
module Handler
  def file_modified
    puts "#{path} modified"
  end

  def unbind
    puts "#{path} monitoring ceased"
  end
end

EventMachine.run do
  EventMachine.watch_file("/tmp/data_packets", Handler)
end
