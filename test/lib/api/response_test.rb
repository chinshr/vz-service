require 'test_helper'

class Api::ResponseTest < ActiveSupport::TestCase
  context "instance methods" do
    setup do
      @api_response = Api::Response.new
    end

    should "have instance" do
      assert_equal Api::Response, @api_response.class
    end

    should "add data" do
      data = {:test => 1}
      @api_response.add_data(data)
      assert_equal data, @api_response.data
    end

    should "add errors" do
      @api_response.add_error(Api::Exception.new)
      assert_equal Api::Code::UNKNOWN, @api_response.code
    end

    should "return json for response success" do
      assert_equal({"code" => Api::Code::SUCCESS}, JSON.parse(@api_response.to_json))
    end

    should "return json for response error" do
      @api_response.add_error(Api::Exception::ArgumentMissing.new(:client_key))
      expected_hash = {"code" => Api::Code::ARGUMENT_MISSING,
        "errors" => {"base" => ["Argument missing 'client_key'"]}}
      assert_equal expected_hash, JSON.parse(@api_response.to_json)
    end

    should "return flat json for response data without root" do
      @api_response = Api::Response.new({access_token: "abcd", access_secret: "1234"})
      expected_hash = {"code" => Api::Code::SUCCESS,
        "access_token" => "abcd", "access_secret" => "1234"}
      assert_equal expected_hash, JSON.parse(@api_response.to_json)
    end

    should "have empty data after cleanup" do
      @api_response.add_data(:test => 1)
      @api_response.cleanup
      assert_equal true, @api_response.data.empty?
    end
  end

  context "class methods" do
    should "return model_name" do
      assert_equal true, Api::Response.model_name.is_a?(ActiveModel::Name)
    end
  end
end
