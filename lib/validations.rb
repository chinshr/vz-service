require 'validations/client_side_validations'

Dir[File.dirname(__FILE__) + "/validations/active_model/**/*.rb"].each {|file| require file}
