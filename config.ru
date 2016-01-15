require './app'

map('/') do
  run App
end

map('/api') do
  run SecureApi
end