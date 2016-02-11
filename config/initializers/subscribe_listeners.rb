Dir.glob(Rails.root.join("app/listeners/**/*_listener.rb")).map do |fn|
  listener_class = Pathname.new(fn).basename('.rb').to_s.classify.constantize
  Wisper::GlobalListeners.subscribe listener_class.new
end
