require 'test_helper'

class RegistrationTest < ActiveSupport::TestCase
  should "validate email formatting" do
    registration = Registration.new :email => "test@example.com"
    assert_no_error_on registration, :email
  end

  should "not validate email formatting" do
    registration = Registration.new :email => "test@com"
    assert_error_on registration, :email
  end

  should "locale" do
    registration = FactoryGirl.create :registration, :locale => "en-US"
    assert_equal "en-US", registration.locale
  end

  should "instance for" do
    reg = Registration.instance_for(
      {:email => "testee@test.com"},
      {"city"=>"Buenos Aires", "region_code"=>"07", "longitude"=>"-58.6725", "region_name"=>"Distrito Federal", "country_code"=>"AR", "latitude"=>"-34.5875", "country_name"=>"Argentina", "ip"=>"190.247.73.246", "zipcode"=>"1640", "metrocode"=>""},
      {:locale => "de-DE", :ip_address => "0.0.0.0"}
    ) do |r|
      r.email = "other@example.com"
    end
    assert_equal "other@example.com", reg.email
    assert_equal "Buenos Aires", reg.city
    # assert_equal "07", reg.region_code
    assert_equal "-58.6725", reg.lng.to_s
    assert_equal "Distrito Federal", reg.region_name
    assert_equal "AR", reg.country_code
    assert_equal "-34.5875", reg.lat.to_s
    assert_equal "0.0.0.0", reg.ip_address
    assert_equal "1640", reg.postal_code
    assert_equal "de-DE", reg.locale
  end
end