def seq( num )
  (num..Float::INFINITY).lazy.map {|x| x + 1 }.take(1).to_a
end


# sweet and short
def next_seq
  (1..1.0/0).lazy.each
end


puts e = next_seq
puts e.next
puts e.next
puts e.next
puts e.next

next_seq = seq(1)
puts "seq = #{next_seq}"
next_seq = seq(next_seq.first)
puts "seq = #{next_seq}"
