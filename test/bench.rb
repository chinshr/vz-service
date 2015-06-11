require 'benchmark'
require 'active_support/core_ext/array'

n = 5000

arr = []
n.times {|i| arr << [i]}


Benchmark.bmbm do |x|
  x.report("[].flatten") { n.times { [arr].flatten } }
  x.report("Array.wrap") { n.times { Array.wrap(arr) } }
  x.report("[*e]") { n.times { [*arr] } }
end