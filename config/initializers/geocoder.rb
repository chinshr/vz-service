Geocoder.configure(
  :timeout => 2,
  :cache   => Redis.new(:url => ENV["REDISTOGO_URL"] || "redis://localhost:6379/")
)