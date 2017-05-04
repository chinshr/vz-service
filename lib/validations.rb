module Validations
  module Middleware; end
end

Dir[File.dirname(__FILE__) + "/validations/**/*.rb"].each {|file| require file}
