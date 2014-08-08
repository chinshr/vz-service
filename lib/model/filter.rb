module Model::Filter
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :class_attribute, :filter_scopes_list
    base.send :filtered_scopes # initalize filter_scopes even if they are not called in the included class
  end
  
  module ClassMethods
    def filter(filter_options)
      return self.all if filter_options.nil?

      raise(ArgumentError, I18n.t('lib.model.filter.argument_error', :input => filter_options.inspect)) unless filter_options.is_a?(Hash)

      @ar_proxy = self.all
      messages = []

      filter_options.except("id", "action", "controller", "format", "signature", "access_id").each do |key, value|
        if self.scopes.map(&:to_s).include?(key) || ["fields", "add_fields", "remove_fields"].include?(key)
          value = ((key == "offset" || key == "limit") && value.to_i <= 0) ? 0 : value
         
          if key == "sort_order"
            Array.wrap(value).flatten.each do |v|
              begin
                if v.is_a?(Hash)
                  v.each do |hk, hv|
                    # E.g. &sort_order[id]=a?... -> Post.send :sort_order, {"id" => "asc"}
                    @ar_proxy = @ar_proxy.send(key.to_sym, {hk.to_s.downcase => ::Model::Helper.sort_orderize(hv)})
                  end
                else
                  # E.g. &sort_order[]=id?... -> Post.send :sort_order, {"id" => "asc"}
                  @ar_proxy = @ar_proxy.send(key.to_sym, {v.to_s.downcase => "asc"})
                end
              rescue ArgumentError => ex
                messages << ex.message
              end
            end
          else
            @ar_proxy = @ar_proxy.send(key.to_sym, value)
          end
        else
          messages << "Ignored unrecognized parameter '#{key}'."
        end
      end
      # TODO Feed 'messages' back to view
      @ar_proxy
    end

    def scopes
      self.filter_scopes_list
    end

    private

    # Allows you to set which filter_scopes are available for each Model.
    # Passing :only => true will replace any inherited scopes defined previously by the parent.
    # The default behavior is to append to the list of inherited scopes (in the case of STI).
    def filtered_scopes(*new_scopes)
      options = new_scopes.extract_options!
      replace_scopes = options.fetch(:only, false)

      scopes_list = if replace_scopes
        new_scopes
      else
        new_scopes + (self.filter_scopes_list || [])
      end

      self.filter_scopes_list = (scopes_list + [:offset, :limit]).uniq
    end
  end
end