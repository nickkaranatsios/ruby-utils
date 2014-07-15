require "pp"

Flavors = Struct.new :cpu, :memory

def Flavors.create(flavor)
  new(*flavor)
end

f = [ ["4", "32"], [8, 64] ]

p = Flavors.method(:create).to_proc

flavors = f.map(&p)
pp flavors
