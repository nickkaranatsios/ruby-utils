def median(x, y, z)
  x + y + z - [x, [y,z].min].min - [x, [y,z].max].max
end

puts median(60, 45, 10)
