require 'json'
require 'json/add/core'
#require 'jsonable'
require 'pp'
require 'securerandom'
#require 'active_model_serializers'
#require 'active_record'

class Other
#  include Jsonable
  attr_accessor :abc

  def initialize(abc)
    @abc = abc
  end

  def to_json(*a)
    result = {}
    result[:class] = self.class.name 
    instance_variables.each do |var|
      result[var.to_s.gsub('@','')] = instance_variable_get(var)
    end
    result.to_json(*a)
  end
end

class MyTest 
#  include Jsonable
  attr_accessor :work_order_id, :other
  def initialize(woid, other)
    @work_order_id = woid
    @other = other
  end
  def print_self
    self.class
  end

  def to_json(*a)
    result = {}
    result[:class] = self.class.name 
    instance_variables.each do |var|
      result[var.to_s.gsub('@','')] = instance_variable_get(var)
    end
    result.to_json(*a)
  end

  def from_json(string)
    JSON.parse(string).each do |var, val|
      next if var =~ /class/
      instance_variable_set("@" + var, val)
    end
  end
end

other = [Other.new("this is a test"), Other.new("this is another test")]
mt = MyTest.new(123, other)

json = mt.to_json
puts json
mt2 = mt.from_json(json)
puts mt2.other

exit

class Base
  def initialize
    self.class_eval do 
      const_get(:FIELDS).each { |field| attr_accessor field }
    end
  end
end

class WorkerAttribute < Base
  attr_reader :adapter_id
  # array of attributes
  attr_reader :trait

  def initialize(adapter_id, trait)
    @adapter_id = adapter_id
    @trait = trait
  end
end

class AccessRightAttribute < Base
  FIELDS = []
end

class Worker < Base
  FIELDS = []

  def initialize(worker_id, name, worker_attrs = nil)
    @worker_id = worker_id
    @name = name
    @worker_attrs = worker_attrs
  end
end

class AccessRightAddRequest < Base
  FIELDS = [].freeze
end

class ConfigurationAttribute < Base
  FIELDS = []
end

class ConfigurationReadRequest < Base
  FIELDS = [].freeze
end

ConfigurationWriteRequest = ConfigurationReadRequest

class EventAlarmRegistrationRequest < Base
  FIELDS = [].freeze
end

class FirewallRule < Base
  FIELDS = []
end

class Profile < Base
  FIELDS = []
end


class DataGenerator
  ADAPTERS = [''].freeze
  GEN_METHODS = [].freeze

  def self.generate
    dg = DataGenerator.new
    
    ADAPTERS.each do |adapter| 
      GEN_METHODS.each do |method|
        puts "#{adapter}: (#{method})"
        puts "=" * 80
        puts dg.send("generate_#{method}", adapter)
        puts "=" * 80
      end
      puts
    end
  end

  def generate_event_alarm_registration_request(adapter)
    worker = nil
    ea_reg_req = EventAlarmRegistrationRequest.new.tap do |klass|
      klass.sequence_number = SecureRandom.hex(32)
      klass.work_order_id = rand(1..2**32)
      klass.request_id = SecureRandom.hex(32)
      if adapter =~ /dc$/
        worker = generate_worker(adapter)
        klass.event_alarm = ""
      end
      if adapter =~ /sc$/
        klass.event_alarm = ""
      end
      if adapter =~ /s$/
        klass.event_alarm = ""
      end
      klass.worker = worker
    end
    ea_reg_req.to_json
  end

  def generate_configuration_write_request(adapter)
    return unless adapter =~ /securitygw$/

    firewall_rules = []
        in_rules = []
    (1..2).each do |i|
      profile = Profile.new.tap do |klass|
        klass.profile = i
        klass.in_rules = [1, 2]
        klass.in_phy_port = "Any"
      end
      firewall_rules << FirewallRule.new.tap do |klass|
        klass.rule_id = i
        in_rules << i
        klass.priority = 2**16 - i
        klass.action = ['Drop', 'Pass', 'Drop_and_Alert', 'Pass_and_Alert'].shuffle[0]
        klass.msg = "Rule <rule id> has been hit: <Msg>"
        klass.source_ip = ['10.40.222.100', '10.40.222.101'][i - 1]
        klass.source_port = rand(1..2**16)
        klass.dest_ip = ['10.40.222.200', '10.40.222.201'][i - 1]
        klass.dest_port = rand(1..2**16)
        klass.proto = ['TCP', 'UDP', 'ICMP'].shuffle[0]
        klass.profiles = profile
      end
    end
    config_attr = ConfigurationAttribute.new.tap do |klass|
      klass.name = "Firewall Rules"
      klass.type = ""
      klass.firewall_rules = firewall_rules
    end
    config_write = ConfigurationWriteRequest.new.tap do |klass|
      klass.sequence_number = SecureRandom.hex(32)
      klass.configuration_attribute = config_attr
    end
    config_write.to_json
  end
    

  def generate_configuration_read_request(adapter)
    return unless adapter =~ /securitygw$/
    config_attr = ConfigurationAttribute.new.tap do |klass|
      klass.name = "Firewall Rules"
      klass.type = ""
    end
    config_read = ConfigurationReadRequest.new.tap do |klass|
      klass.sequence_number = SecureRandom.hex(32)
      klass.configuration_attribute = config_attr
    end
    config_read.to_json
  end

  def generate_access_right_request(adapter)
    worker = generate_worker(adapter)
    ar_attr = generate_access_right_attr(adapter)
    ar = generate_access_right(worker, ar_attr)
    ar.to_json
  end

  private

  def generate_worker(adapter)
    worker = nil
    if adapter =~ /dl$/
      wa = WorkerAttribute.new(adapter, populate_worker_attributes(2))
      worker = Worker.new(rand(1..2**32), "John Smith", wa)
    end
  end

  def populate_worker_attributes(no_of_traits)
    trait = Array.new(no_of_traits, {})
    (0..1).each do  |i|
      card_id = rand(1..2**32)
      trait[i] = { card_id: card_id, face_id: card_id }
    end
    trait
  end

  def generate_access_right_attr(adapter)
    AccessRightAttribute.new.tap do |klass|
      klass.access_right_id = SecureRandom.hex(32)
      klass.adapter = adapter
      if adapter =~ /dl$/
         klass.name = ""
         klass.content = ""
      end
      if adapter =~ /s$/
        klass.name = ""
        klass.content = ""
      end
      if adapter =~ /s$/
        klass.name = ""
        klass.content = ""
      end
    end
  end

  def generate_access_right(worker, ar_attr)
    ar = AccessRightAddRequest.new.tap do |klass|
      klass.sequence_number = SecureRandom.hex(32)
      klass.work_order_id = rand(1..2**32)
      klass.worker = worker
      klass.access_right_attribute = ar_attr
      klass.start_time = Time.now
      klass.end_time = Time.now + (60 * 60 * 2)
    end
  end
end

DataGenerator.generate
