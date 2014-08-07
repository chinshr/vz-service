module Mailer; end
Dir[File.dirname(__FILE__) + "/mailer/**/*.rb"].each {|file| require file}
