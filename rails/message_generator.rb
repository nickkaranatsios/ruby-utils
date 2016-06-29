require 'json'
require 'pp'
require 'securerandom'
require 'jbuilder'
require 'active_model_serializers'

class Base
  def included(base)
    base.include ActiveModel::Serializers
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

  def to_builder
    Jbuilder.new do |builder|
      builder.(self, :adapter_id, :trait)
    end
  end
end

class AccessRightAttribute < Base
  FIELDS = [:access_right_id, :adapter, :name, :content]
  
  FIELDS.each do |field|
    attr_accessor field
  end

  def to_builder
    Jbuilder.new do |ar_attr|
      ar_attr.(self, :access_right_id, :adapter, :content)
    end
  end
end

class Worker < Base
  FIELDS = [:worker_id, :name, :worker_attrs]
  FIELDS.each do |field|
    attr_accessor field
  end

  def initialize(worker_id, name, worker_attrs = nil)
    @worker_id = worker_id
    @name = name
    @worker_attrs = worker_attrs
  end

  def to_builder
    Jbuilder.new do |builder|
      builder.worker_id  worker_id
      builder.name  name
      unless worker_attrs.nil?
        builder.worker_attrs  worker_attrs.to_builder
      end
    end
  end
end

class AccessRightAddRequest < Base
  FIELDS = [:sequence_number, :work_order_id, :worker, :access_right_attribute, :start_time, :end_time].freeze

  FIELDS.each do |field|
    attr_accessor field
  end

  def to_builder
    Jbuilder.new do |ar_add_req|
      ar_add_req.sequence_number  sequence_number
      ar_add_req.work_order_id  work_order_id
      unless worker.nil?
        ar_add_req.worker  worker.to_builder
      end
      ar_add_req.access_right_attribute  access_right_attribute.to_builder
      ar_add_req.start_time  start_time
      ar_add_req.end_time  end_time
    end
  end
end

class ConfigurationAttribute < Base
  FIELDS = [:name, :type, :firewall_rules]
  
  FIELDS.each do |field|
    attr_accessor field
  end

  def to_builder
    Jbuilder.new do |builder|
      builder.name name
      builder.type type
      unless firewall_rules.nil?
        #builder.firewall_rules firewall_rules.each { |f| f.to_builder }
        builder.firewall_rules do
          Jbuilder.new.array!(firewall_rules) do |f|
            f.to_builder
          end
        end
      end
    end
  end
end

class ConfigurationReadRequest < Base
  FIELDS = [:sequence_number, :configuration_attribute].freeze

  FIELDS.each do |field|
    attr_accessor field
  end

  def to_builder
    Jbuilder.new do |builder|
      builder.sequence_number sequence_number
      builder.configuration_attribute configuration_attribute.to_builder
    end
  end
end

ConfigurationWriteRequest = ConfigurationReadRequest

class EventAlarmRegistrationRequest < Base
  FIELDS = [:sequence_number, :work_order_id, :worker, :request_id, :event_alarm].freeze

  FIELDS.each do |field|
    attr_accessor field
  end

  def to_builder
    Jbuilder.new do |ea_req|
      ea_req.sequence_number sequence_number
      ea_req.work_order_id work_order_id
      unless ea_req.worker.nil?
        ea_req.worker worker.to_builder
      end
      ea_req.event_alarm event_alarm
    end
  end
end

class FirewallRule
  FIELDS = [:rule_id, :priority, :action, :msg, :source_ip, :source_port, :dest_ip, :dest_port, :proto, :profiles]

  FIELDS.each do |field|
    attr_accessor field
  end

  def to_builder
puts "fr builder"
    Jbuilder.new do |builder|
      builder.rule_id rule_id
      builder.priority priority
      builder.action  action
      builder.msg msg
      builder.source_ip source_ip
      builder.source_port source_port
      builder.dest_ip dest_ip
      builder.dest_port dest_port
      builder.proto proto
      builder.profiles profiles.to_builder
    end
  end
end

class Profile
  FIELDS = [:profile, :in_rules, :in_phy_port]

  FIELDS.each do |field|
    attr_accessor field
  end

  def to_builder
    Jbuilder.new do |builder|
      builder.profile profile
      builder.in_rules in_rules
      builder.in_phy_port in_phy_port
    end
  end
end


class DataGenerator
  ADAPTERS = ['com:nec:cps:2.0:subsystem:doorcontrol', 'com:nec:cps:2.0:subsystem:surveillancecamera', 'com:nec:cps:2.0:subsystem:securitygw'].freeze
  GEN_METHODS = ['access_right_request', 'configuration_read_request', 'configuration_write_request', 'event_alarm_registration_request'].freeze

  def self.generate
    dg = DataGenerator.new
    
    ADAPTERS.each do |adapter| 
      GEN_METHODS.each do |method|
        puts "#{adapter} -> #{method}"
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
      if adapter =~ /doorcontrol$/
        worker = generate_worker(adapter)
        klass.event_alarm = "successful access on <card_reader_group> in <system name>"
      end
      if adapter =~ /surveillancecamera$/
        klass.event_alarm = "entry detected in <area name> of <camera name> in <system name>"
      end
      if adapter =~ /securitygw$/
        klass.event_alarm = "port link up on <physical port> in <system name>"
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
      klass.type = "com:nec:cps:2.0:subsystem:securitygw:configuration:firewallrules"
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
      klass.type = "com:nec:cps:2.0:subsystem:securitygw:configuration:firewallrules"
    end
    config_read = ConfigurationReadRequest.new.tap do |klass|
      klass.sequence_number = SecureRandom.hex(32)
      klass.configuration_attribute = config_attr
    end
    config_read.to_builder.target!
  end

  def generate_access_right_request(adapter)
    worker = generate_worker(adapter)
    ar_attr = generate_access_right_attr(adapter)
    ar = generate_access_right(worker, ar_attr)
    ar.to_builder.target!
  end

  private

  def generate_worker(adapter)
    worker = nil
    if adapter =~ /doorcontrol$/
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
      if adapter =~ /doorcontrol$/
         klass.name = "permit access on inside area"
         klass.content = "permit access on <card reader group> in <system name> with facial enabled"
      end
      if adapter =~ /surveillancecamera$/
        klass.name = "permit access on inside area"
        klass.content = "permit access in <area name> of <camera name> in <system name>"
      end
      if adapter =~ /securitygw$/
        klass.name = "permit access on inside area"
        klass.content = "permit access on <physical port> in <system name> using <profile> with packet capture enabled"
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
