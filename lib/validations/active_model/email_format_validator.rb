class EmailFormatValidator < ::ActiveModel::EachValidator
  REGEXP   = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  REGEXPJS = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

  def validate_each(object, attribute, value)
    unless value =~ REGEXP
      object.errors.add(attribute, :email_format, options)
    end
  end
end
