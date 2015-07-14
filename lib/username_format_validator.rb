class UsernameFormatValidator < ActiveModel::EachValidator
  REGEXP = /^[a-zA-Z0-9_]{2,15}$/i

  def validate_each(object, attribute, value)
    unless value =~ REGEXP
      object.errors.add(attribute, :username_format, options)
    end
  end
end