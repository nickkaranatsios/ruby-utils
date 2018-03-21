require 'eventmachine'
require 'evma_httpserver'
require 'json'

class MyHttpServer < EM::Connection
  include EM::HttpServer

  def post_init
    super
    no_environment_strings
  end

  def process_http_request
    #   @http_protocol
    #   @http_request_method
    #   @http_cookie
    #   @http_if_none_match
    #   @http_content_type
    #   @http_path_info
    #   @http_request_uri
    #   @http_query_string
    #   @http_post_content
    #   @http_heade
    puts "http post content #{@http_post_content}"
    puts "http post uri #{@http_request_uri}"
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type  'application/json'
    response.content = { 'message_class': 'TestClass'}.to_json
    response.send_response
  end
end

EM.run do
  EM.start_server '0.0.0.0', 4555, MyHttpServer
end
