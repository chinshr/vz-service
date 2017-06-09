require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Voyzes
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    I18n.enforce_available_locales = true

    # Filter passwords
    config.filter_parameters += [:password, :card_number, :card_cvc]

    config.middleware.use Rack::Deflater
    initializer "app.hack" do |app|
      # removes Rack::Deflator as added with heroku_rails_deflate.
      # Reasoning, see http://www.oak.homeunix.org/~marcel/blog/2015/03/25/keep-alives-with-rails-on-heroku
      app.config.middleware.delete Rack::Deflater
    end

    # TODO Rails 5 upgrade: set true when callbacks refactored with `throw(:abort)`
    # See http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#halting-callback-chains-via-throw-abort
    ActiveSupport.halt_callback_chains_on_return_false = true

    # TODO Rails 5 belongs_to requires assocations
    # See http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#active-record-belongs-to-required-by-default-option
    config.active_record.belongs_to_required_by_default = false

    # TODO Rails 5 csrf tokens per form
    # See http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#per-form-csrf-tokens
    config.action_controller.per_form_csrf_tokens = true

    # TODO Rails 5 origin protection check
    config.action_controller.forgery_protection_origin_check = true

    # TODO Rails 5 queue name optional
    # See http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#allow-configuration-of-action-mailer-queue-name
    config.action_mailer.deliver_later_queue_name = :mailers

    # TODO Rails 5
    # See http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#configure-the-output-of-db-structure-dump
    config.active_record.dump_schemas = :all

    # TODO Rails 5
    # See http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#preserve-timezone-of-the-receiver
    ActiveSupport.to_time_preserves_timezone = false
  end
end
