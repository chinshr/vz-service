module Model::Helper
  extend self

  def date_parse(date)
    if date.is_a?(String)
      DateTime.parse( date )
    elsif date.acts_like?(:time) || date.acts_like?(:date)
      date
    else
      raise ArgumentError.new(I18n.t("api.error.argument_error"))
    end
  end

  def booleanize(param)
    return case param.to_s.downcase
    when "true", "1" then true
    when "false", "0", "" then false
    else
      raise ArgumentError.new(I18n.t("api.error.boolean_argument_error"))
    end
  end

  def sort_orderize(param)
    return case param.to_s.downcase
    when "asc", "a" then "asc"
    when "desc", "d" then "desc"
    else
      raise ArgumentError.new(I18n.t("api.error.sort_order_argument_error"))
    end
  end
end