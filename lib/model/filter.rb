module Model::Filter
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :class_attribute, :available_scopes_list
    base.send :available_scopes # Initalize available_scopes even if they are not called in the included class
  end
  
  module ClassMethods
    def filter(filter_options)
      return self.scoped if filter_options.nil?

      raise(ArgumentError, I18n.t('lib.model.filter.argument_error', :input => filter_options.inspect)) unless filter_options.is_a?(Hash)

      @ar_proxy = self.scoped
      @ar_proxy = @ar_proxy.reorder('') if self.include?(CollectiveIdea::Acts::NestedSet::Model) # Removes nested_sets default ordering on roots and other descendent methods
      messages = []

      filter_options.except("id", "action", "controller", "format", "signature", "access_id").each do |key, value|
        if self.scopes.map(&:to_s).include?(key) || ["fields", "add_fields", "remove_fields"].include?(key) || key[Model::HStoreSupport::SCOPE_NAMING_FORMAT]
         value = ((key == "offset" || key == "limit") && value.to_i <= 0) ? 0 : value
            
          if key == "sort_order"
            Array.wrap(value).each do |v|
              begin
                @ar_proxy = @ar_proxy.send(key.to_sym, v)
              rescue ArgumentError => e
                messages << e.message
              end
            end
          elsif ["fields", "add_fields", "remove_fields"].include?(key)
            @ar_proxy.relation_store.add(key.to_sym, value)
          else
            @ar_proxy = @ar_proxy.send(key.to_sym, value)
          end
        else
          messages << "Ignored unrecognized parameter '#{key}'."
        end
      end

      @ar_proxy.messages = messages
      @ar_proxy
    end

    def scopes
      self.available_scopes_list
    end

    private

    # Allows you to set which scopes are available for each Model.
    # Passing :only => true will replace any inherited scopes defined previously by the parent.
    # The default behavior is to append to the list of inherited scopes (in the case of STI).
    def available_scopes(*new_scopes)
      options = new_scopes.extract_options!
      replace_scopes = options.fetch(:only, false)

      scopes_list = if replace_scopes
        new_scopes
      else
        new_scopes + (self.available_scopes_list || [])
      end

      self.available_scopes_list = (scopes_list + [:offset, :limit]).uniq
    end
  end
end