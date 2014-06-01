require 'pp'

a = Array.new( 10 ) { | e | e + 100 }
indexed_set = a.each_index.to_a

pp indexed_set
