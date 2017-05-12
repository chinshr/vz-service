# BigDecimal got converted to string instead of floats
# Solution here https://github.com/rails/rails/issues/25017
require 'active_support'
require 'active_support/core_ext/object/json'

class BigDecimal
  def as_json(*)
    to_f
  end
end
