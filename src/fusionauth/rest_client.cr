# Copyright (c) 2019, FusionAuth, All Rights Reserved
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require "base64"
require "json"
require "uri"
require "http/client"
require "http/headers"
require "http/params"

module FusionAuth
  class RESTClient
    @client : HTTP::Client
    @body_handler : BodyHandler? = nil
    @method : String? = nil
    @path : String? = nil

    def initialize(uri : URI)
      @client = HTTP::Client.new(uri)
      @client.connect_timeout = 1000
      @client.read_timeout = 2000
    end

    def authorization(authorization : String)
      @client.before_request do |request|
        request.headers["Authorization"] = authorization
      end
      self
    end

    def basic_authorization(username : String, password : String)
      @client.basic_auth(username, password)
      self
    end

    def body_handler(@body_handler : BodyHandler)
      self
    end

    def certificate
      yield @client.tls?
      self
    end

    def connect_timeout(connect_timeout : Number)
      @client.connect_timeout = connect_timeout
      self
    end

    def read_timeout(read_timeout : Number)
      @client.read_timeout = read_timeout
      self
    end

    {% for method in %w(delete get patch post put) %}
    def {{method.id}}
      @method = {{method.upcase}}
      self
    end
    {% end %}

    def header(name : String, value : String)
      @client.before_request do |request|
        request.headers[name] = value
      end
      self
    end

    def headers(headers : Hash)
      @client.before_request do |request|
        request.headers.merge!(headers)
      end
      self
    end

    def uri(uri : String)
      @path = uri
      self
    end

    #
    # Add a URL parameter as a key value pair.
    #
    # @param name [String] The URL parameter name.
    # @param value [String} ]The url parameter value. The <code>.toString()</ code> method will be used to
    #              get the <code>String</code> used in the URL parameter. If the object type is a
    #             @link Collection} a key value pair will be added for each value in the collection.
    #             @link ZonedDateTime} will also be handled uniquely in that the <code>long</ code> will
    #              be used to set in the request using <code>ZonedDateTime.toInstant().toEpochMilli()</code>
    # @return This.
    #
    def url_parameter(name : String?, value)
      return self if name.nil?

      parameters = [] of String

      case value
      when Array
        value.each do |item|
          if item.responds_to?(:to_s)
            parameters << item.to_s.strip
          end
        end
      else
        if value.responds_to?(:to_s)
          parameters << value.to_s.strip
        end
      end

      @client.before_request do |request|
        parameters.each do |param|
          request.query_params.add(name.not_nil!, param)
        end
      end

      self
    end

    #
    # Append a url path segment. <p>
    # For Example: <pre>
    #     .url("http://www.foo.com ")
    #     .urlSegment(" bar ")
    #   </pre>
    # This will result in a url of <code>http://www.foo.com/bar</code>
    #
    # @param value The url path segment. A nil value will be ignored.
    # @return This.
    #
    def url_segment(value : String?)
      return self if value.nil?

      @client.before_request do |request|
        request.path += "/#{value.not_nil!.strip}"
      end

      self
    end

    def go
      if @path.nil?
        raise ArgumentError.new("You must specify a URL")
      end

      if @method.nil?
        raise ArgumentError.new("You must specify a HTTP method")
      end

      @client.before_request do |request|
        @body_handler.try &.handle_request(request)
      end

      response = ClientResponse.new

      begin
        http_response = @client.exec(HTTP::Request.new(@method.not_nil!, @path.not_nil!))

        response.status = http_response.status_code
        is_body_permitted = http_response.class.mandatory_body?(http_response.status)
        is_json = http_response.content_type == "application/json"

        if http_response.success?
          if is_body_permitted && is_json && http_response.body?
            response.success_response = JSON.parse(http_response.body)
          end
        else
          if is_body_permitted && is_json && http_response.body?
            response.error_response = JSON.parse(http_response.body)
          end
        end
      rescue ex
        response.exception = ex
      end

      response
    end
  end

  class ClientResponse
    property status : Int32 = -1
    property success_response : JSON::Any? = nil
    property error_response : JSON::Any? = nil
    property exception : Exception? = nil

    def was_successful
      if @status != -1
        HTTP::Status.new(@status).success?
      else
        false
      end
    end
  end

  alias BodyHandler = JSONBodyHandler | FormDataBodyHandler

  class FormDataBodyHandler
    @body : Hash(String, String | Array(String))

    def initialize(@body)
    end

    def handle_request(request)
      request.body = HTTP::Params.encode(@body)
      set_headers(request.headers)
    end

    #
    # Sets any headers necessary for the body to be processed.
    #
    # @param headers [Hash] The headers hash to add any headers needed by this BodyHandler
    # @return [Object] The object
    private def set_headers(headers)
      headers["Content-Type"] = "application/x-www-form-urlencoded"
      nil
    end
  end

  class JSONBodyHandler
    @body : String

    def initialize(body : Hash)
      @body = body.to_json
    end

    def handle_request(request)
      request.body = @body
      set_headers(request.headers)
    end

    #
    # Sets any headers necessary for the body to be processed.
    #
    # @param headers [Hash] The headers hash to add any headers needed by this BodyHandler
    # @return [Object] The object
    private def set_headers(headers)
      headers["Length"] = @body.bytesize.to_s
      headers["Content-Type"] = "application/json"
      nil
    end
  end
end
