require 'digest/bubblebabble'

class Generator
  def initialize no_times
    @random_arr = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    @no_times = no_times
  end


  def output_mutation_to
    shuffle_string = shuffle
    shuffle_array = shuffle_string.split("-")
    f1, f2, f3 = shuffle_array.each_slice(shuffle_array.size / 3).to_a
    puts f1.join("-")
    puts f2.join("-")
    puts f3.join("-")
    puts shuffle_string
    @no_times.times do | each |
      t = Time.now
      t.strftime("%m/%d/%Y %H:%I:%S")
      
    end 
  end

  private

  def shuffle
    Digest::SHA256.bubblebabble mutate_population
  end

  def mutate_population
    @random_arr.shuffle.take(10).join
  end
end

#t.strftime("%m/%d/%Y %H:%I:%S")
# a = "2" * 10
# "X" * 3 - sa001
# cnt = cnt + 1
# "NG"
# "3"
# "mail"
# 4 file names separated with spaces + 1 space at the end
# size of file in size for a maximum of 2 file names
no_times = ARGV[0] || 1000
generator = Generator.new no_times
generator.output_mutation_to
