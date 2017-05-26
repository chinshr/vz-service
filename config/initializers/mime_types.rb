# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
Mime::Type.register "audio/mpeg3", :mp3
Mime::Type.register "application/x-subrip", :srt
Mime::Type.register "text/plain", :txt

# http://www.ietf.org/rfc/rfc4627.txt
# http://www.json.org/JSONRequest.html
# Mime::Type.register "application/json", :json, %w( text/x-json application/jsonrequest )

# http://blog.bigbinary.com/2010/11/23/mime-type-resolution-in-rails.html
# Create Mime::ALL but do not add it to the SET.
# Mime::ALL = Mime::Type.new("*/*", :all, [])
