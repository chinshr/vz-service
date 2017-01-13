require "core_ext/i18n/locale"

# ==with
#
# We have been struggling with the absence of @with@ blocks
# in Ruby for a long time. We had something similar in
# Object Pascal where it came quite handy as a reserved
# keyword.
#
# Let me explain what it does:
#
#    with Invoice.find_by_id(params[:id]) do |invoice|
#      puts invoice.total
#    end
#
# or
#
#    @order, @invoice = with @order, @invoice do |order, invoice|
#      invoice.total = order.total
#    end
#
#  and essentially this resolves to how we used to
#  to things in Ruby:
#
#    if invoice = Invoice.find_by_id(params[:id])
#      invoice.total
#    end
#
# See: http://bit.ly/14iimBe, page 93
#
def with(*evaluated_objects, &block)
  yield(*evaluated_objects) if evaluated_objects.all? {|o| o}
  evaluated_objects.size == 1 ? evaluated_objects.first : evaluated_objects
end
