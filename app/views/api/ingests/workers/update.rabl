object @worker => :worker
extends "api/ingests/workers/attributes"
node do |u|
  {errors: u.errors}
end
