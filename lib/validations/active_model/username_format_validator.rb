class UsernameFormatValidator < ::ActiveModel::EachValidator
  REGEXP   = /\A[a-zA-Z0-9_]{2,15}\z/i
  REGEXPJS = /^[a-zA-Z0-9_]{2,15}$/i

  def validate_each(object, attribute, value)
    unless value =~ REGEXP
      object.errors.add(attribute, :username_format, options)
    end
  end
end
