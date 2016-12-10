require "hashie"
require "pp"

class IfLogic < Hash
	include Hashie::Extensions::Coercion
	coerce_key :spec, IfLogic
end

rule_specs = []
if_logic_spec = { "operator" => "if", "args" => Array }
rule_specs << IfLogic.new(spec: if_logic_spec)

class MergeLogic < Hash
	include Hashie::Extensions::Coercion
	coerce_key :spec, MergeLogic
end

merge_logic_spec = { "operator" => "merge", "args" => Array }
rule_specs << MergeLogic.new(spec: merge_logic_spec)

rule = { 
	"if" => [
    {"merge" =>  [
      {"missing" =>["first_name", "last_name"]},
      {"missing_some" => [1, ["cell_phone", "home_phone"] ]}
    ]},
    "We require first name, last name, and one phone number.",
    "OK to proceed"
  ]}

rule.extend Hashie::Extensions::DeepFind, Hashie::Extensions::DeepLocate

data = {"first_name"=> "Bruce", "last_name" => "Wayne"}

def rule_conforms_to(rule_specs, value)
	puts "value to check if conforming #{value}"
	rule_specs.each do |rspec|
		rspec.operator == value.first
	end
end

def transform(rule, rule_specs, data, trx_result = {}, result = [])
	if rule.is_a?(::Enumerable)
		if rule.any? {|value| rule_conforms_to(rule_specs, value) }
			result.push rule
		else
			(rule.respond_to?(:values) ? rule.values : rule.entries).each do |value|
				transform(rule, rule_specs, data, trx_result, result)
			end
		end
	end
end

transform(rule, rule_specs, data)
