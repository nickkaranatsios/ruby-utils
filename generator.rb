require 'digest/bubblebabble'

class Generator
  def initialize
    @random_arr = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  end

  def shuffle
    Digest::SHA256.bubblebabble mutate_population
  end

  private

  def mutate_population
    @random_arr.shuffle.take(10).join
  end
end

#t.strftime("%m/%d/%Y %H:%I:%S")
# a = "2" * 10
generator = Generator.new
puts generator.shuffle
