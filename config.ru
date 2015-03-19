# This file is used by Rack-based servers to start the application.

# http://blog.codeship.com/middleman-s3-deploy/
require 'rack/reverse_proxy'
use Rack::ReverseProxy do
  reverse_proxy /^\/documentation\/?(.*)$/, 'http://doc.voyz.es.s3-website-us-east-1.amazonaws.com/documentation/$1'
end

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application
