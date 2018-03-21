require 'pp'

class Aggregate
  class << self
    def transform
      puts "transform is called"
      new().transform
    end
  end

  def initialize
    puts "aggregate contructor is called"
  end 

  def transform
    puts "transform instance called"
  end
end


Aggregate.transform

