module Helper::Mailer
  extend self
    
  # tries to return a regular email address from a pretty printed email
  #
  # e.g.
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
    emails && emails.match(/\b[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]+\b/i)).to_a
  end

end