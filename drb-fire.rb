require "drb/drbfire"

front = ['a', 'b', 'c', 'd']
DRb.start_service('drbfire://1.1.1:5555', front, DRbFire::ROLE => DRbFire::SERVER)
DRb.thread.join
