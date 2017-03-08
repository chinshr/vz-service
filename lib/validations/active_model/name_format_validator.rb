class NameFormatValidator < ::ActiveModel::EachValidator
  REGEXP   = /\A[^0-9`!@#\$%\^&*+_=]+\z/i
  REGEXPJS = /^[^0-9`!@#\$%\^&*+_=]+$/i

  def validate_each(object, attribute, value)
    unless value =~ REGEXP
      object.errors.add(attribute, :name_format, options)
    end
  end
end

