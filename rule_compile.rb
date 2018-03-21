require "hashie"
require "pp"

class BaseCoercable < Hash
	include Hashie::Extensions::Coercion
  include Hashie::Extensions::MergeInitializer
end

class Logic < BaseCoercable
  coerce_key :operator, String
end
# need a way to define the specification of jsonlogic rules that can easily be
# checked when required. In other words given an input can call conforms_to to
# check the conformance of  the logic.
class JsonLogicOperator < BaseCoercable
	coerce_key :specs, Array[String]
end

specs_hash = []
%w(if merge missing missing_some == var).each  do |logic|
  specs_hash << { operator: logic }
end
operators = JsonLogicOperator.new(specs: specs_hash)
operators.extend Hashie::Extensions::DeepFind, Hashie::Extensions::DeepLocate

#{:specs=>
#  [{:operator=>"if"},
#   {:operator=>"merge"},
#   {:operator=>"missing"},
#   {:operator=>"missing_some"},
#   {:operator=>"var"}]}
#["if", "merge", "missing", "missing_some", "var"]

rule_specs = operators.deep_find_all(:operator)


class Hash
	def or_logic(key, value)
		puts "or logic"
	end
	def equal_logic(key, value)
		puts "equal logic for #{value}"
		[true, false].sample
	end

	def var_logic(operators, key, value)
		puts "var logic"
	end

	alias == equal_logic
	alias or or_logic
	alias var var_logic
end


h = {
          "or": [
            {
              "==": [
                {
                  "var": "cs5"
                },
                "internal"
              ]
            },
            {
              "==": [
                {
                  "var": "cs5"
                },
                "DMZ"
              ]
            }
          ]
        }
a = h[:or]
b = a.map do |e|
	k, v = e.first
	e.send(k, k, v)
end
puts b
exit


def rule_conforms_to(rule_specs, value)
  if value.is_a?(Array)
    value.each do |v|
      puts "v #{v} #{rule_specs.include?(v)}"
      rule_specs.include?(v)
    end
   elsif value.is_a?(Hash)
    value.extend Hashie::Extensions::DeepLocate
    value.deep_locate ->(key, value, object) do
      puts "k #{key} #{rule_specs.include?(key)}"
      rule_specs.include?(key)
    end
  end
end

rule = {
	if:  [
    { merge:  [
      { missing: ["first_name", "last_name"]},
      { missing_some: [1, ["cell_phone", "home_phone"] ]}
    ]},
    "We require first name, last name, and one phone number.",
    "OK to proceed"
  ]}

rule = {
	missing:
  { merge: [
    "vin",
    {if: [{var:"financing"}, ["apr", "term"], [] ]}
  ]}
}

rule ={
  "set_{local|remote}": [
    {
      "collection": "connection_with_non_whitelist_countries"
    },
    {
      "source_address": {
        "var": "sourceAddress"
      }
    },
    {
      "destination_address": {
        "var": "destinationAddress"
      }
    },
    {
      "source_geo_country": {
        "var": "sourceGeoCountry"
      }
    },
    {
      "source_address_zone": {
        "var": "cs4"
      }
    },
    {
      "destination_address_zone": {
        "var": "cs5"
      }
    }
  ],
  "if": [
    {
      "and": [
        {
          "!": [
            {
              "in": [
                {
                  "var": "sourceGeoCountry"
                },
                {
                  "get_remote": "whitelist_countries"
                }
              ]
            }
          ]
        },
        {
          "==": [
            {
              "var": "cs4"
            },
            "external"
          ]
        },
        {
          "or": [
            {
              "==": [
                {
                  "var": "cs5"
                },
                "internal"
              ]
            },
            {
              "==": [
                {
                  "var": "cs5"
                },
                "DMZ"
              ]
            }
          ]
        }
      ]
    },
    {
      "aggregate": [
        {
          "get_{local|remote}": "connection_with_non_whitelist_countries"
        },
        {
          "group_by": {
            "name": "source_address",
            "as": "source_address"
          }
        }
      ]
    },
    "{}"
  ]
}


rule.extend Hashie::Extensions::DeepFind, Hashie::Extensions::DeepLocate, Hashie::Extensions::DeepFetch

def transform_keys_recursively!(object)
	case object
		when Hash
			transform_keys!(object)
		when Array
			object.each do |e|
				transform_keys_recursively!(e)
			end
	end
end

def map_array(k, arr)
	puts "map array #{k}"
	arr.map do |e|
		puts "e #{e} to be  mapped"
	end
end

def transform_keys!(hash)
	hash.keys.each do |k|
puts "k #{k} value #{hash[k]}"
puts hash[k].class
		if hash[k].is_a?(Array)
			hash[k].extend(Hashie::Extensions::DeepLocate)
			found = hash[k].deep_locate -> (key, value, object) { key != k}
			puts "found = #{found}"
			if found.size == 1
				map_array(k, hash[k])
			end
		end
		transform_keys_recursively!(hash[k])
#		hash[k.to_sym] = hash.delete(k)
	end
	hash
end

def transform_rule(hash)
	copy = hash.dup
	copy.tap do |new_hash|
		transform_keys!(new_hash)
	end
end

transform_rule(rule)
#pp rule
exit

puts rule.class
result = []
rule.each_pair do |k, v|
	result << Hash[k, v]
	pp rule.deep_select(k)
	puts "*" * 20
end
puts "result"
pp result
exit


keys = rule.keys
keys.each do |k|
	v =  rule[k]
	pp k
	pp v
end
exit
enum = rule.respond_to?(:values) ? rule.values : rule.entries
result = []

while enum.is_a?(::Enumerable)
  puts "we are here #{enum}"
  enum.each do |value|
    if value.is_a?(Hash)
			k, v = value.first
      puts "key = #{k}"
      result << Hash[k, v]
		end
#    if rule_conforms_to(rule_specs, value)
#      puts "value conforms #{value} #{value.class}" if rule_conforms_to(rule_specs, value)
#    end
  end
  enum = enum.first
	puts "ignore #{enum}"
  break unless enum.is_a?(::Enumerable)
  enum = enum.respond_to?(:values) ? enum.values : enum.entries
end

puts result.size
pp result
result.each do |e|
	k, _v = e.first
	puts "key to construct method #{k}"
	puts "method to call #{e.first}"
end

exit

data = {"first_name"=> "Bruce", "last_name" => "Wayne"}


def transform(rule, rule_specs, data, tx_result = {}, result = [])
	if rule.is_a?(::Enumerable)
		if rule.any? {|value| rule_conforms_to(rule_specs, value) }
			result.push rule
		end
	  if (rule.respond_to?(:values) ? rule.values : rule.entries).each do |value|
				transform(rule, rule_specs, data, tx_result, result)
			end
		end
	end
end

transform(rule, rule_specs, data)
