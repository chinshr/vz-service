require "i18n/backend/fallbacks"
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

I18n.fallbacks[:en] = [:en]
I18n.fallbacks[:es] = [:es, :en]
=begin
I18n.fallbacks[:pt] = [:pt, :en]
I18n.fallbacks[:de] = [:de, :en]
I18n.fallbacks[:it] = [:it, :en]
I18n.fallbacks[:fr] = [:fr, :en]
I18n.fallbacks[:nl] = [:nl, :en]
I18n.fallbacks[:pl] = [:pl, :en]
I18n.fallbacks[:cs] = [:cs, :en]
I18n.fallbacks[:da] = [:da, :en]
I18n.fallbacks[:sv] = [:sv, :en]
I18n.fallbacks[:no] = [:no, :en]
I18n.fallbacks[:fi] = [:fi, :en]
I18n.fallbacks[:et] = [:et, :en]
I18n.fallbacks[:el] = [:el, :en]
I18n.fallbacks[:tr] = [:tr, :en]
I18n.fallbacks[:af] = [:af, :en]
I18n.fallbacks[:he] = [:he, :en]
I18n.fallbacks[:ru] = [:ru, :en]
I18n.fallbacks[:ar] = [:ar, :en]
I18n.fallbacks[:ja] = [:ja, :en]
I18n.fallbacks[:zh] = [:zh, :en]
I18n.fallbacks[:ko] = [:ko, :en]
I18n.fallbacks[:hi] = [:hi, :en]
=end