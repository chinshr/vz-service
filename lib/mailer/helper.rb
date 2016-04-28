module Mailer::Helper
  extend self

  # tries to return a regular email address from a pretty printed email
  #
  # E.g.
  #
  #   "John Smith <j@s.com>" -> "j@s.com"
  #
  def unprettify(email)
    email && email.match(/\<(.*)\>/) ? $1 : email
  end

  def prettify(name, email_address)
    "#{name} <#{email_address}>"
  end

  def unprettify_multiples(emails)
    emails && emails.scan(/\b[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]+\b/i).compact
  end

  # E.g. my+en-us@voyz.es or my+de@voyz.es -> "de-DE"
  def locale_from_email_address(email)
    result = nil
    if (tri = email.to_s.split("+")).size > 1
      if (bi = tri.last.split("@")).size > 1
        if bi.first.match(/^([a-z]{2}[-_]{1}[A-Z]{2}|[a-z]{2})$/i)
          result = I18n.normalize_locale($1)
        end
      end
    end
    result
  end

end