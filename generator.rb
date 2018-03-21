#!/usr/bin/env ruby

require 'digest/bubblebabble'

class Generator
  def initialize no_times
    @random_arr = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    @no_times = no_times
  end


  def output_mutation_to
    @no_times.times do |i|
      output_arr = []
      t = Time.now
      f1 = t.strftime("%m/%d/%Y %H:%I:%S")
      output_arr << f1

      f2 = "X" * 3 + "-sa01"
      output_arr << f2

      f3 = "#{i}" * 10 
      output_arr << f3

      f4 = "NG"
      output_arr << f4

      f5 = "3"
      output_arr << f5

      f6 = "mail"
      output_arr << f6

      shuffle_string = shuffle
      shuffle_array = shuffle_string.split("-")
      fn1, fn2 = shuffle_array.each_slice(shuffle_array.size / 2).to_a
      #
      #["xuseg", "kykif", "bybav", "metop", "zofun"]
      #["pocom", "fofok", "fifon", "rycok", "bisib"]
      #["lyliv", "dadul", "karor", "govek", "vapap"]
      ext = %w(.pdf .js .scr).shuffle.take(1)[0]
      #f7 = fn1.join('-') + ext + " " + fn2.join('-') + ext  + " " + fn3.join('-') + ext + " "
      res1 = fn1.take(4).join("-") + "_" + fn1[-4] + "-" + fn1[-2,2].to_a.join("-") + ext
      res2 = fn2.take(4).join("-") + "_" + fn2[-4] + "-" + fn2[-2,2].to_a.join("-") + ext
      f7 = res1 + " " + res2 + " "
      output_arr << f7
      
      f8 = fn1.length.to_s * 4 + " " + fn2.length.to_s * 4 + " "
      output_arr << f8

      puts output_arr.collect {|each| "\"" + each + "\"" }.join(",")
    end 
    # File.open("fn", "w") do |f|
    #   f << "this is a test"
    # end
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
no_times = ARGV[0].to_i || 2
generator = Generator.new no_times
generator.output_mutation_to
