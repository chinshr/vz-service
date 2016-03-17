require 'test_helper'

class ImageTest < ActiveSupport::TestCase

  context "associations" do
    # should belong_to(:image_format)
    should belong_to(:ingest)
  end

  context "validations" do
    subject { FactoryGirl.create(:image) }

    should validate_presence_of(:image_format_id)
    should validate_presence_of(:path)
    should validate_numericality_of(:size)
  end

  context "#create" do
    should "be valid" do
      assert_difference "Image.count" do
        FactoryGirl.create(:image, :document_ingest)
      end
    end

    should "copy attributes from image_format on create" do
      image = FactoryGirl.create(:image, :document_ingest)
      assert_equal image.image_format.width, image.width
      assert_equal image.image_format.height, image.height
      assert_equal image.image_format.format, image.format
      assert_equal image.image_format.aspect_ratio, image.aspect_ratio
    end

    should "not copy attributes when image_formats have changed" do
      image = FactoryGirl.create(:image, :document_ingest)
      image.image_format.width  = 1
      image.image_format.height = 1
      image.image_format.format = 'foo'
      image.image_format.aspect_ratio = 2.2
      image.image_format.save!
      image.save
      assert_not_equal image.image_format.width, image.width
      assert_not_equal image.image_format.height, image.height
      assert_not_equal image.image_format.format, image.format
      assert_not_equal image.image_format.aspect_ratio, image.aspect_ratio
    end
  end

  context "Model::Iteration" do
    should "#iteration" do
      image = FactoryGirl.build(:image, :document_ingest)
      image.ingest.iteration = 5
      assert_equal true, image.valid?
      assert_equal 5, image.iteration
    end

    context "scopes" do
      setup do
        @image = FactoryGirl.create(:image,
          ingest: FactoryGirl.create(:image_ingest, iteration: 1,
            ingestable: FactoryGirl.create(:document)))
      end

      should "#iteration" do
        assert_equal @image, Image.iteration_eq(1).first
      end
    end
  end

  context "#url" do
    setup do
      @image = FactoryGirl.create(:image, :document_ingest)
    end

    should "should return a url that ends with path" do
      assert_equal "#{File.join(APP_CONFIG['INGEST_IMAGE_ASSET_HOST'], @image.path)}", @image.url
    end
  end

  context "#destroy" do
    setup do
      @image = FactoryGirl.create(:image, :document_ingest)
    end

    should "act paranoid" do
      assert_difference "Image.count", -1 do
        @image.destroy
        assert_not_nil @image.deleted_at
      end
    end

    should "enqueue delete job" do
      assert_enqueued_with(job: Image::DeleteJob) do
        @image.destroy
      end
    end
  end
end
