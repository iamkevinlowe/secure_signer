# 1) You sign the request on client (non-browser client) side
#   - String to sign = request.method + request.parameters + request.path

# 2) Serverside looks up the secret based on the access key you send along with your signed request

# 3) The serverside uses the secret to sign the INCOMING request using the same algo that the client used.

# 4) The signatures are then comapred, if they match, then you're good to go, otherwise render a 400/401

# assuming request is an object that has the following methods:
# #method (the http method)
# #parameters (the query string/form parameters)
# #path (the path of the request)

# Tokens
#access_key
#secret_key

#Authorization #{access_key}:#{base_64_encoded_signature}

require 'sinatra/base'
require 'openssl'
require 'base64'
require 'json'

Request = Struct.new :method, :parameters, :path

Keys = {
  abcde: "fghij"
}

# Middleware for authorization check
class SecureAuth
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTP_AUTHORIZATION']
      auth_header = env['HTTP_AUTHORIZATION'].split(':')
      public_key = auth_header[0]
      signature = auth_header[1]

      incoming_request = Request.new(env['REQUEST_METHOD'], env['QUERY_STRING'], env['REQUEST_PATH'])

      if sign(incoming_request, Keys[public_key.to_sym]) == signature
        @app.call(env)
      else
        respond_401
      end
    else
      respond_401
    end
  end

  private

  def sign(request, secret_token)
    string = request.method + request.parameters + request.path
    digest = OpenSSL::Digest.new('sha256')
    signature = OpenSSL::HMAC.digest(digest, secret_token, string)
    Base64.strict_encode64(signature)
  end

  def respond_401
    status = 401
    response = ["Unauthorized"]
    headers = {'Content-Length' => response[0].length.to_s}

    [status, headers, response]
  end
end

# Public app
class App < Sinatra::Base
  get '/' do
    erb :home
  end
end

# Secured API
class SecureApi < Sinatra::Base
  use SecureAuth

  before do
    content_type :json
  end

  get '/powerballs' do
    response = {
      powerballs: []
    }

    5.times do
      ball = rand(69) + 1
      redo if response[:powerballs].include? ball
      response[:powerballs] << ball
    end
    response[:powerballs] << rand(26) + 1

    response.to_json
  end
end