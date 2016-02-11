require 'test_helper'

class Model::S3Test < ActiveSupport::TestCase
  class IngestOrUpload < ::Ingest
    include Model::S3
  end

  setup do
    @ingest = IngestOrUpload.new
  end

  should "#s3_base_url" do
    assert_equal "http://s3.amazonaws.com", @ingest.s3_base_url
  end

  should "#s3_upload_bucket_name" do
    assert_equal "vz-test-dropbox", @ingest.s3_upload_bucket_name
  end

  should "#s3_origin_bucket_name" do
    assert_equal "vz-test-origin", @ingest.s3_origin_bucket_name
  end

  should "#has_origin_url?" do
    @ingest[:origin_url] = "http://s3.amazonaws.com/vz-origin/3o6njggbog03s5odak5y"
    assert_equal true, @ingest.send(:has_origin_url?)
  end

  should "not #has_origin_url?" do
    assert_equal false, @ingest.send(:has_origin_url?)
  end

  should "#has_s3_source_url?" do
    @ingest[:source_url] = "http://s3.amazonaws.com/vz-test-dropbox/3o6njggbog03s5odak5y"
    assert_equal true, @ingest.send(:has_s3_source_url?)
  end

  should "not #has_s3_source_url?" do
    @ingest.stubs(:source_url).returns("http://fancy.com")
    assert_equal false, @ingest.send(:has_s3_source_url?)
  end

  should "#s3_origin_key from origin_url" do
    @ingest.stubs(:origin_url).returns("http://s3.amazonaws.com/vz-dev-origin/caa3c30b-620f-4683-842e-026c4926a2dc/ohvoq16o5p22xfz7wk7y")
    assert_equal "caa3c30b-620f-4683-842e-026c4926a2dc/ohvoq16o5p22xfz7wk7y", @ingest.s3_origin_key
  end

  should "#s3_origin_key from uid and handle" do
    @ingest.stubs(:origin_url).returns(nil)
    @ingest.stubs(:uid).returns("abcd")
    @ingest.stubs(:handle).returns("1234")
    assert_equal "abcd/1234", @ingest.s3_origin_key
  end

  should "#s3_origin_url with origin_url" do
    @ingest[:origin_url] = "http://s3.amazonaws.com/vz-dev-origin/caa3c30b-620f-4683-842e-026c4926a2dc/ohvoq16o5p22xfz7wk7y"
    assert_equal "http://s3.amazonaws.com/vz-dev-origin/caa3c30b-620f-4683-842e-026c4926a2dc/ohvoq16o5p22xfz7wk7y", @ingest.s3_origin_url
  end

  should "#s3_origin_url with uid and handle" do
    @ingest.stubs(:uid).returns("abcd")
    @ingest.stubs(:handle).returns("1234")
    assert_equal "http://s3.amazonaws.com/vz-test-origin/abcd/1234", @ingest.s3_origin_url
  end
end
