require "pp"

# computes the powerset of an array
a = Array.new( 4 ) { | e | e + 1 }
pp a
ps = []
ps << []
( 1..a.length ).each do | e |
  a.combination( e ).each do | n |
    ps << n.flatten 
  end
end

pp ps
