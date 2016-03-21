require 'pp'

d = Array.new(8, rand(0..255)) { Array.new(8, rand(0..255)) }
t = Array.new(8, 0) { Array.new(8, 0) }
e = Array.new(8, 0) { Array.new(8, 0) }

def sign(x)
  res = 1 if x >= 0
  res = -1 if x < 0
  return res
end

def abs(x)
  res = x if x >= 0
  res = -x if x < 0
  return res
end

(0..7).each do |i|
  e[i][0] = (d[i][0] + d[i][4]) * 181  >> 7
  e[i][1] = (d[i][0] - d[i][4]) * 181 >> 7
  e[i][2] = (d[i][2] * 196 >> 8) - (d[i][6] * 473 >> 8)
  e[i][3] = (d[i][2] * 473 >> 8) + (d[i][6] * 196 >> 8)
  t[i][4] = d[i][1] - d[1][7]
  t[i][7] = d[i][1] + d[i][7]
  t[i][5] = d[i][3] * 181 >> 7
  t[i][6] = d[i][5] * 181 >> 7
  e[i][4] = t[i][4] + t[i][6]
  e[i][5] = t[i][7] - t[i][5]
  e[i][6] = t[i][4] - t[i][6]
  e[i][7] = t[i][7] + t[i][5]
end

f = Array.new(8, 0) { Array.new(8, 0) }
(0..7).each do |i|
  f[i][0] = e[i][0] + e[i][3]
  f[i][3] = e[i][0] - e[i][3]

  f[i][1] = e[i][1] + e[i][2]
  f[i][2] = e[i][1] - e[i][2]

  f[i][4] = (e[i][4] * 301 >> 8) - (e[i][7] * 201 >> 8)
  f[i][7] = (e[i][4] * 201 >> 8) + (e[i][7] * 301 >> 8)

  f[i][5] = (e[i][5] * 710 >> 9) - (e[i][6] * 141 >> 9)
  f[i][6] = (e[i][5] * 141 >> 9) - (e[i][6] * 710 >> 9)
end

g = Array.new(8, 0) { Array.new(8, 0) }
(0..7).each do |i|
  g[i][0] = f[i][0] + f[i][7]
  g[i][7] = f[i][0] - f[i][7]

  g[i][1] = f[i][1] + f[i][6]
  g[i][6] = f[i][1] - f[i][6]

  g[i][2] = f[i][2] + f[i][5]
  g[i][5] = f[i][2] - f[i][5]

  g[i][3] = f[i][3] + f[i][4]
  g[i][4] = f[i][3] - f[i][4]
end

h = Array.new(8, 0) { Array.new(8, 0) }
(0..7).each do |j|
  h[0][j] = (g[0][j] + g[4][j]) * 181 >> 7
  h[1][j] = (g[0][j] - g[4][j]) * 181 >> 7

  h[2][j] = (g[2][j] * 196 >> 8) - (g[6][j] * 473 >> 8)
  h[3][j] = (g[2][j] * 473 >> 8) + (g[6][j] * 196 >> 8)

  t[4][j] = g[1][j] - g[7][j]
  t[7][j] = g[1][j] + g[7][j]

  t[5][j] = g[3][j] * 181 >> 7
  t[6][j] = g[5][j] * 181 >> 7 

  h[4][j] = t[4][j] + t[6][j]
  h[5][j] = t[7][j] - t[5][j]

  h[6][j] = t[4][j] - t[6][j]
  h[7][j] = t[7][j] + t[5][j]
end

m = Array.new(8, 0) {Array.new(8, 0)}
(0..7).each do |j|
  m[0][j] = h[0][j] + h[3][j]

  m[3][j] = h[0][j] - h[3][j]
  m[1][j] = h[1][j] + h[2][j]

  m[2][j] = h[1][j] - h[2][j]
  m[4][j] = (h[4][j] * 301 >> 8) - (h[7][j] * 201 >> 8)

  m[7][j] = (h[4][j] * 201 >> 8) + (h[7][j] * 301 >> 8)
  m[5][j] = (h[5][j] * 710 >> 9) - (h[6][j] * 141 >> 9)
  
  m[6][j] = (h[5][j] * 141 >> 9) + (h[6][j] * 710 >> 9)
end

n = Array.new(8, 0) { Array.new(8, 0) }
(0..7).each do |j|
  n[0][j] = m[0][j] + m[7][j]
  n[7][j] = m[0][j] - m[7][j]

  n[1][j] = m[1][j] + m[6][j]
  n[6][j] = m[1][j] - m[6][j]

  n[2][j] = m[2][j] + m[5][j]
  n[5][j] = m[2][j] - m[5][j]

  n[3][j] = m[3][j] + m[4][j]
  n[4][j] = m[3][j] - m[4][j]
end

r = Array.new(8, 0) { Array.new(8, 0) }
(0..7).each do |i|
  (0..7).each do |j|
    r[i][j] = sign((abs(n[i][j]) + 16) >> 5) * n[i][j]
  end
end


pp e
pp t
pp f
pp g
pp h
pp m
pp n
pp r
