module Model::Virtus
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
  end

  # Include this in a collection model, like:
  #
  #    class FooCollection
  #      include Model::Virtus::Collection
  #      collection_of Foo
  #    end
  #
  module Collection
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def collection_of(class_name)
        class_eval(<<-END, __FILE__, __LINE__+1)
          def <<(object)
            if object.kind_of?(Hash)
              super(#{class_name}.new(object))
            else
              super
            end
          end

          def coerce(values)
            if !values[:id] || values[:id].blank?
              # add new, e.g. {'name'=>"foobar", ...}
              values.merge!({id: SecureRandom.uuid})
              self << values
            elsif values.try(:[], :id).present? && !values[:_delete]
              # update existing, e.g. {'id'=>"xyz-", ...}
              if index = self.index {|object| object.id == values[:id]}
                if self[index].blank?
                  self[index] = #{class_name}.new(values)
                else
                  self[index].attributes = values
                end
              else
                self << values
              end
            elsif values.try(:[], :id).present? && values[:_delete]
              # delete, e.g. {'id'=>"xyz-2h234", '_delete'=>true}
              if index = self.index {|object| object.id == values[:id]}
                delete_at(index)
              end
            end
            self
          end
        END
      end
    end
  end

  module ActiveModel
    def self.included(base)
      base.send :include, ::ActiveModel::Model
      base.send :include, ::ActiveModel::Serialization
      base.send :include, ::Virtus.model(nullify_blank: true)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def coerce(values)
        self.attributes = values
        self
      end

      private

      def secure_random_id
        self.id = SecureRandom.uuid
      end
    end

    module ClassMethods

      def complex_attribute(attribute_name, type = nil, options = {})
        self.attribute attribute_name, type, options

        class_eval(<<-END, __FILE__, __LINE__+1)
        def #{attribute_name}=(values)
          if values.is_a?(Hash)
            attribute = attribute_set[:#{attribute_name}]
            object = attribute.get(self) || attribute.primitive.new
            super(object.coerce(ActiveSupport::HashWithIndifferentAccess.new(values)))
          else
            super(values)
          end
        end
        END
      end

      # Is added to the model with the collection attribute
      #
      # Usage:
      #
      # class Foo
      #   ...
      #   attribute :bars, BarCollection[Bar], default: BarCollection.new
      #   collection_attribute :bars
      #   ...
      # end
      #
      def collection_attribute(attribute_name, type = nil, options = {})
        self.attribute attribute_name, type, options

        class_eval(<<-END, __FILE__, __LINE__+1)
          def #{attribute_name}=(values)
            if values.is_a?(Array)
              values.each {|v| self.#{attribute_name} = v}
            elsif values.is_a?(Hash)
              attribute = attribute_set[:#{attribute_name}]
              collection = #{attribute_name}.blank? ? attribute.primitive.new : #{attribute_name}
              super(collection.coerce(ActiveSupport::HashWithIndifferentAccess.new(values)))
            else
              super(values)
            end
          end
        END
      end
    end
  end
end
