REDIS ||= begin
  if Rails.env.production?
    uri   = URI.parse(ENV["REDISTOGO_URL"] || "redis://localhost:6379/" )
    Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    Redis.new
  end
end
