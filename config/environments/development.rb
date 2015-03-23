Voyzes::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Set to :debug to see everything in the log.
  config.log_level = :debug   # :info

  # Rack::Cache
=begin
  config.static_cache_control = "public, max-age=#{12.hours * 60.seconds}"  # default for Chache-Control, e.g. 2592000
  config.action_dispatch.rack_cache = {
    metastore:          'file:tmp/cache/rack/meta',
    entitystore:        'file:tmp/cache/rack/body',
    allow_reload:       false,
    allow_revalidate:   false,
    verbose:            true,
    cache_key:          lambda {|request|
      [request.env["HTTP_HOST"], Rack::Cache::Key.new(request).generate].reject(&:blank?).map {|s| Digest::MD5.hexdigest(s)}.join(":")
    }
  }
=end
end