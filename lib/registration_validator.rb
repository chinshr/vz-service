class RegistrationValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless ::Registration.accepted.where("registrations.email ILIKE ?", value).any?
      record.errors.add(attribute, :register_email, options.merge(value: value))
    end
  end
end