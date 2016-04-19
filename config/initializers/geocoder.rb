REDIS ||= begin
  if Rails.env.production?
    uri   = URI.parse(ENV["REDISTOGO_URL"] || "redis://localhost:6379/" )
    Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    Redis.new
  end
end

if Rails.env.production?
  Geocoder.configure({
    :timeout   => 2,
    :cache     => REDIS,
    :use_https => true,
    :google    => {
      :api_key => "AIzaSyBFNbBpOsfzZ2-60jchxzgkwa9YkEK5z8E"
    },
    :ip_lookup => :geoip2,
    :geoip2 => {
      lib: 'maxminddb',
      file: File.join(Rails.root, 'lib', 'assets', 'GeoLite2-Country.mmdb')
    }
  })
else
  Geocoder.configure({
    :timeout => 2,
    :ip_lookup => :geoip2,
    :geoip2 => {
      lib: 'maxminddb',
      file: File.join(Rails.root, 'lib', 'assets', 'GeoLite2-Country.mmdb')
    }
  })
end