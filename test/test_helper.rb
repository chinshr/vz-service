ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'shoulda'
require 'sidekiq/testing'
require 'geocoder'
require 'webmock/minitest'

Sidekiq::Testing.fake!
AWS.stub!

Geocoder.configure(:lookup => :test, :timeout => 0)
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'latitude'     => 40.7143528,
      'longitude'    => -74.0059731,
      'address'      => 'New York, NY, USA',
      'state'        => 'New York',
      'state_code'   => 'NY',
      'country'      => 'United States',
      'country_code' => 'US'
    }
  ]
)

#WebMock.disable_net_connect!(:net_http_connect_on_start => true)
Warden.test_mode!

class ActiveSupport::TestCase
  require "mocha/setup"
  
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  include Shoulda::Matchers::ActiveRecord 
  extend Shoulda::Matchers::ActiveRecord 
  include Shoulda::Matchers::ActiveModel 
  extend Shoulda::Matchers::ActiveModel 
  
  setup do
    stub_request(:get, "freegeoip.net/json/95.63.14.59").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{}", :headers => {})
  end
end

class ActionController::TestCase
  include Devise::TestHelpers
  include Warden::Test::Helpers
  
  protected
  
  def response_body
    # TODO: if response is JSON.parse else XML
    JSON.parse(response.body)
  end
  
  def assert_response_body_attributes_with(envelope)
    body = response_body
    assert body.has_key?(envelope.to_s), "should have envelope '#{envelope}'"
    assert_attributes body[envelope.to_s]
  end

end

