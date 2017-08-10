ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'rack/test'
require_relative '../web'

class HelloWorldTest < Test::Unit::TestCase
  def test_it_says_hello_world
    browser = Rack::Test::Session.new(Rack::MockSession.new(Sinatra::Application))
    browser.get '/'

    assert browser.last_response.ok?
    assert_equal "ruby-sinatra\n", browser.last_response.body
  end
end
