require "pp"

def next_seq
  (1..1.0/0).lazy.each
end

# computes the powerset of an array
a = Array.new( 4 ) { | e | e + 1 }
e = next_seq

ps = []
begin
  num = e.next
  a.combination(num).inject(ps,:<<)
end while num < a.length
pp ps

ps = []
ps << []
( 1..a.length ).each do | e |
  a.combination( e ).each do | n |
    ps << n.flatten 
  end
end

pp ps
