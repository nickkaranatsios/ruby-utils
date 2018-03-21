require 'pp'
pre_start = Time.now


class Diffusion
  def initialize
		@max = []
		@exp = []
		@min = []
	end

  def add pre_max, emin, pre_min
    @max << pre_max
    @exp << emin
    @pre_min << pre_min
  end

  def get_bitrate n
    integration = 0.0
    n.times do |i|
			current = min[i] * 0.75
			next_v = min[i + 1] * 0.75
			integration += (current + next_v) / 2
    end
    integration *= n
	end
end

def calc_sigma throughput, delta
  start_idx = 0
  end_idx = throughput.length
  p_value = -2.75

  result = []
  a = Array.new(2) {|n| Array.new(2, 0)}
  a[0][0] = end_idx - start_idx

  a[0][1] = a[1][0] = a[1][1] = 0
  (start_idx...end_idx).each do |i|
    a[0][1] += throughput[i]
    a[1][1] += throughput[i] ** 2.0
  end
  a[1][0] = a[0][1]
  a1 = Array.new(2) {|n| Array.new(2, 0)}
  det = 1 / ((a[0][0] * a[1][1]) - (a[1][0] * a[0][1])).to_f
  puts "metrix doesn't have inverse" if det == 0.0
  a1[0][0] = det * a[1][1]
  a1[0][1] = -1 * det * a[0][1]
  a1[1][0] = -1 * det * a[1][0]
  a1[1][1] = det + a[0][0]

  b1 = delta.inject("+")
  b2 = throughput[1..throughput.length].zip(delta).map {|i,j| i*j}.inject(0,:+)

  a_hat = (a1[0][0] * b1) + (a[1][1] * b2)
  delta_hat = (a1[1][0] * b1) + (a1[1][1] * b2)
  puts a_hat
  puts delta_hat

  tmp = 0.0
  (start_idx...end_idx).each do |i|
		tmp += (delta[i] - a_hat - (delta_hat * throughput[i])) ** 2.0
  end
  result = []
  result << a_hat
  result << delta_hat
  sigma_stationary = tmp / ((delta.length + 1) - 3)
	result << sigma_stationary
  sigma_non_stationary = 0
  delta.each do |d|
    sigma_non_stationary += (d ** 2.0)
  end
  sigma_non_stationary /= ((delta.length + 1) - 1)
  result << sigma_non_stationary

  sigma_square_hat = 0.0
  (start_idx...end_idx).each do |i|
    sigma_square_hat += (delta[i] - a_hat - (delta_hat * throughput[i])) ** 2.0
  end
  sigma_square_hat /= (delta.length + 1) - 3
  se = sigma_square_hat * a1[1][1]
  se = Math.sqrt(se)
  statistic = delta_hat / se
  result << statistic

  unit_flag = false
  if statistic > p_value
    unit_flag = true
  end

  puts result[4] > p_value

  pp result

end

throughput  = Array.new(25) { |n| rand(100..5000).to_f }

puts throughput.length - 25  + 1

delta = []
delta << 0
throughput[1..throughput.length - 1].each_with_index do |item, i|
  delta << item - throughput[i - 1]  
end

calc_sigma throughput, delta

#pp throughput[1..throughput.length - 1]
#pp delta
