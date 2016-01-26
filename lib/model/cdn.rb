# Make sure ENV["SERVICE_STREAMING_ASSETS_URL"] is set; most likely it would be in config/heroku_env.rb
module Model::CDN
  class << self
    def included(base)
      %w{file_path path}.each do |attribute|
        self.url_from_path(attribute) if base.attribute_names.include?(attribute)
      end
    end

    # This will create #file_url or #url from #file_path or #path, depending on
    # which attribute name is defined on the base model. The base of the URL will
    # be determined by instance methods @assets_base_url_key@ or @assets_base_url@
    # in the base model.
    #
    # If neither of these are defined in the base model, the base URL will default
    # to the URL defined in ENV["SERVICE_STREAMING_ASSETS_URL"].
    #
    # A method @assets_base_url_key@ defined in the base model returns the environment
    # key to lookup the asset base url.
    #
    #     def assets_base_url_key; "SERVICE_STATIC_ASSETS_URL"; end
    #
    # or, a @assets_base_url@ is defined in the base model that returns the 
    # base that is prepended to the path.
    #
    #     def assets_base_url; "https://static.service.com"
    #
    # Note: @assets_base_url@ defined in the model has priority over @assets_base_url_key@.
    #
    # Example:
    #
    #     class Image < ActiveRecord::Base
    #        include Model:CDN
    #
    #        def assets_base_url; "http://static.service.com"; end
    #     end
    #
    #     @image.path # -> "images/image_208x156.jpg"
    #     @image.url  # -> "http://static.service.com/images/image_208x156.jpg"
    #
    def url_from_path(attribute)
      method_name = attribute.gsub("path", "url")
      define_method(method_name.to_sym) do
        begin
          if respond_to?(:assets_base_url)
            base_url = send(:assets_base_url)
          end
          File.join(base_url, self.send(attribute.to_sym))
        rescue IndexError
          raise ArgumentError.new(I18n.t('lib.model.cdn.method_missing'))
        end
      end
    end
  end
end