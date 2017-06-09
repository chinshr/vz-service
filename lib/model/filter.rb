module Model::Filter
  def self.included(base)
    base.send :extend, ClassMethods
    base.send :class_attribute, :filter_scopes_list
    base.send :filtered_scopes # initalize filter_scopes even if they are not called in the included class
  end

  module ClassMethods
    PRIORITY_KEYS = ["limit", "offset"].freeze
    EXCEPTED_KEYS = ["id", "action", "controller", "format"].freeze

    def filter(filter_options)
      return self.all if filter_options.blank?
      raise(ArgumentError, I18n.t('lib.model.filter.argument_error', :input => filter_options.inspect)) unless filter_options.is_a?(Hash) || filter_options.is_a?(ActionController::Parameters)

      scope = self.all
      messages  = []

      filter_options.as_json.except(*EXCEPTED_KEYS).sort {|v| PRIORITY_KEYS.include?(v.to_s) ? -1 : 1}.each do |tuple|
        key, value = tuple.first, tuple.last
        if self.scopes.map(&:to_s).include?(key)
          value = ((key == "offset" || key == "limit") && value.to_i <= 0) ? 0 : value

          if key == "sort_order"
            Array.wrap(value).flatten.each do |v|
              begin
                if v.is_a?(Hash)
                  v.each do |hk, hv|
                    # E.g. &sort_order[id]=a?... -> Post.send :sort_order, {"id" => "asc"}
                    scope = scope.send(key.to_sym, {hk.to_s.downcase => ::Model::Helper.sort_orderize(hv)})
                  end
                else
                  # E.g. &sort_order[]=id?... -> Post.send :sort_order, {"id" => "asc"}
                  scope = scope.send(key.to_sym, {v.to_s.downcase => "asc"})
                end
              rescue ArgumentError => ex
                messages << ex.message
              end
            end
          else
            scope = scope.send(key.to_sym, value)
          end
        else
          messages << "Ignored unrecognized parameter '#{key}'."
        end
      end
      # TODO Feed 'messages' back to view
      scope
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