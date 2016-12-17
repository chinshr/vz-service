module CoreExt
  module ActiveModel
    module Type
      module TypeCast

        def type_cast_from_user(value)
          cast_value(value)
        end

      end
    end
  end
end

ActiveModel::Type::Integer.send(:include, CoreExt::ActiveModel::Type::TypeCast)
ActiveModel::Type::String.send(:include, CoreExt::ActiveModel::Type::TypeCast)
