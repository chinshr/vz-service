ENV["RAILS_ENV"] ||= "test"
ENV["PUBNUB_DISABLED"] ||= "true"
ENV["CODECLIMATE_REPO_TOKEN"] ||= "131d67864fbd157df1e2a2745c5d9a1bbed1783706ff91f1178a5913ba5013eb"

# require 'simplecov'
# SimpleCov.start
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'shoulda'
require 'sidekiq/testing'
require 'geocoder'
require 'webmock/minitest'
require 'active_job/test_helper.rb'
require 'wisper/minitest/assertions'

SimpleCov.start do
  add_filter "/vendor/" # Ignores any file containing "/vendor/" in its path.
end

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

WebMock.disable_net_connect!(allow_localhost: true, allow: ["codeclimate.com"])
Warden.test_mode!

class SQSTestQueue
  attr_accessor :name

  def initialize(name = "empty")
    @name = name
  end

  def send_message(message)
    message
  end
end

class ActiveSupport::TestCase
  require "mocha/setup"

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
  include ActiveJob::TestHelper

  def assert_error_on(record, *fields)
    record.valid?
    fields.each do |field|
      assert !record.errors[field.to_sym].empty?, "expected errors on #{field}"
    end
  end

  def assert_no_error_on(record, *fields)
    record.valid?
    fields.each do |field|
      assert record.errors[field.to_sym].empty?, "expected no errors on #{field}"
    end
  end

  setup do
    # stub geoip
    stub_request(:get, "freegeoip.net/json/95.63.14.59").
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => "{}", :headers => {})

    # pubnub, currently not working
    stub_request(:any, /.*pubnub.com.*/)

    # Stubs SQS
    @sqs_queue  = SQSTestQueue.new
    @sqs_queues = mock("AWS::SQS::Queues")
    @sqs_queues.stubs(:named).returns(@sqs_queue)
    @sqs_proxy  = mock("AWS::SQS::Proxy")
    @sqs_proxy.stubs(:queues).returns(@sqs_queues)
    @sqs        = AWS::SQS.stubs(:new).returns(@sqs_proxy)
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

  def assert_response_body_attributes_with(envelope, expected_attributes = {}, method = :assert_attributes)
    body = response_body
    assert body.has_key?(envelope.to_s), "should have envelope '#{envelope}'"
    expected_attributes = Array.wrap(expected_attributes).inject({}) {|r,i| r[i] = nil; r} unless expected_attributes.is_a?(Hash)
    expected_attributes.stringify_keys!
    send method, body[envelope.to_s], expected_attributes
  end

  def assert_attributes(params, expected_attributes = {})
    flunk "Missing implementation for assert_attributes."
  end
end

