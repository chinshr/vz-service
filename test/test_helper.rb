ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'shoulda'
require 'sidekiq/testing'
require 'geocoder'
require 'webmock/minitest'

Sidekiq::Testing.fake!
AWS.stub!

Geocoder.configure(:lookup => :test)
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
end

