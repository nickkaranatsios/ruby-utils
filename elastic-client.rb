require 'multi_json'
require 'faraday'
require 'elasticsearch/api'
require 'jbuilder'

class MySimpleClient
  include Elasticsearch::API

  CONNECTION = ::Faraday::Connection.new url: 'http://localhost:9200'

  def perform_request(method, path, params, body)
    puts "--> #{method.upcase} #{path} #{params} #{body}"

    CONNECTION.run_request \
      method.downcase.to_sym,
      path,
      ( body ? MultiJson.dump(body): nil ),
      {'Content-Type' => 'application/json'}
  end
end

client = MySimpleClient.new

p client.cluster.health

p client.index index: 'workorders', type: 'mytype', id: 'custom', body: { title: "indexing from my client" }

query = Jbuilder.encode do |json|
  json.query do
  	json.match do
			json.title do
				json.query 'indexing from my client' 
				json.operator 'and'
			end
		end
	end
end

client.search index: 'myindex', body: query
