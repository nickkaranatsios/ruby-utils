require "pp"

Flavors = Struct.new :cpu, :memory, :created_at

def Flavors.create(flavor)
  new(*flavor)
end

def Flavors.set(*args)
  args << Time.now
  new(*args)
end

flavors = []
flavors << Flavors.set(4, 32)
pp flavors
exit


f = [ ["4", "32"], [8, 64] ]

p = Flavors.method(:create).to_proc

flavors = f.map(&p)
flavors << Flavors.create([32, 256])
flavors.each do |f|
  puts "f.cpu #{f.cpu}"
end
