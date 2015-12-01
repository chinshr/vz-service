# I18n core extensions of functionality formerly available in Globalize1
module CoreExt
  module I18n
    module Locale
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Allows you to switch the current locale while within the block.
        # The previously current locale is reset after the block is finished.
        #
        # E.g
        #
        #     I18n.locale = :'en-US'
        #     I18n.switch_locale :'es-ES' do
        #       product.name = 'pan'
        #     end
        #
        #     product.name #   --> bread
        #
        def switch_locale(code)
          current_locale = I18n.locale
          I18n.locale = code
          result = yield
          I18n.locale = current_locale
          result
        end
        alias_method :with_locale, :switch_locale   # make it more Globalize2 like

        # Returns true if the currently set locale is the default_locale
        # this is analogous to Globalize Locale.base?
        def default_locale?
          I18n.default_locale == I18n.locale
        end

        # Returns the language specific portion of the locale as code symbol
        #
        # E.g.
        #
        #   :de-DE     I18n.locale_language -> :de
        #   :en        I18n.locale_language -> :en
        #   :"it-IT"   I18n.locale_language -> :it
        #
        def locale_language(in_locale = locale)
          in_locale.to_s.match(/^(\w{2})/) ? $1.to_sym : nil
        end

        def humanized_locale_language(locale = nil)
          ::I18n.t("languages.#{locale_language(locale || ::I18n.locale)}")
        end

        # Returns the country specific portion of locale as code symbol
        #
        # E.g.
        #
        #   :de-DE     I18n.locale_country_code  -> :DE
        #   :en        I18n.locale_country_code  -> nil
        #   :"it-IT"   I18n.locale_country_code -> :IT
        #   "de_DE"   I18n.locale_country_code -> :DE
        #
        def locale_country(in_locale = locale)
          in_locale.to_s.match(/[_-](\w{2})$/) ? $1.to_sym : nil
        end

        def active_locales
          fallbacks.reject {|k,v| k.to_s.length < 2}.keys.compact.uniq
        rescue NoMethodError => ex
          raise "I18n.fallbacks must be setup to determine active locales"
        end

        def active_locale_languages
          active_locales.map {|l| locale_language(l)}.compact.uniq
        end

        # Right-to-left language? E.g. Hebrew or Arabic
        def rtl?
          t("site.direction", :default => "ltr") == "rtl"
        end

        # "en_US" instead of "en-US"
        def web_locale(in_locale = locale)
          result = "#{locale_language(in_locale)}"
          result += "_#{locale_country(in_locale)}" if locale_country(in_locale)
          result
        end

        def normalize_locale(in_locale)
          result = []
          result.push(locale_language(in_locale)) if locale_language(in_locale)
          result.push(locale_country(in_locale)) if locale_country(in_locale)
          result.join("-")
        end
      end
    end
  end
end

I18n.send :include, CoreExt::I18n::Locale
