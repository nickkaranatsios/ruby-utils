require 'socket'
u1 = UDPSocket.new
u1.bind('127.0.0.1', 4913)


u2 = UDPSocket.new

u2.connect("127.0.0.1", 4913)
u2.send "uuuu", 0

data = u1.recvfrom(10)
p data

