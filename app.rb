# 1) You sign the request on client (non-browser client) side
#   - String to sign = request.method + request.parameters + request.path

# 2) Serverside looks up the secret based on the access key you send along with your signed request

# 3) The serverside uses the secret to sign the INCOMING request using the same algo that the client used.

# 4) The signatures are then comapred, if they match, then you're good to go, otherwise render a 400/401

# assuming request is an object that has the following methods:
# #method (the http method)
# #parameters (the query string/form parameters)
# #path (the path of the request)

require 'sinatra'
require 'openssl'
require 'base64'

Request = Struct.new :method, :parameters, :path

def sign_request(request, secret_token)
  string = request.method + request.parameters + request.path
  digest = OpenSSL::Digest.new('sha256')
  signature = OpenSSL::HMAC.digest(digest, secret_token, string)
  Base64.strict_encode64(signature)
end

# Tokens
#access_key
#secret_key

keys = {
  abcde: "fghij"
}

#Authorization #{access_key}:#{base_64_encoded_signature}

before do
  pass if request.path == '/' || request.path =='/set_auth_header'

  if env['HTTP_AUTHORIZATION']
    auth_header = env['HTTP_AUTHORIZATION'].split(':')
  else
    halt 401
  end

  public_key = auth_header[0]
  signature = auth_header[1]
  incoming_request = Request.new(request.request_method, request.query_string, request.path)

  if sign_request(incoming_request, keys[public_key.to_sym]) == signature
    pass
  else
    halt 401
  end
end

get '/' do
  erb :home
end

get '/set_auth_header' do
  outgoing_request = Request.new('GET', '', '/test')
  signature = sign_request(outgoing_request, keys[:abcde])
  request.env['authorization'] = "abcde:#{signature}"
  request.path_info = '/test'
  pass
end

get '/test' do
  "Success"
end

error 401 do
  "Authorization Failure"
end