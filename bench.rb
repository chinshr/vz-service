require 'benchmark'
require 'active_support/core_ext/array'

n = 500000

Benchmark.bmbm do |x|
  x.report("[].flatten") { n.times { [["a"]].flatten } }
  x.report("Array.wrap") { n.times { Array.wrap(["a"]) } }
end