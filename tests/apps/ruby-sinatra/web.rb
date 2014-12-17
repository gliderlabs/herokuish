require 'sinatra'

set :port, ENV["PORT"] || 5000

get '/' do
  "ruby-sinatra\n"
end
