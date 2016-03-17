extends "api/uploads/attributes"
attributes :metadata
child(:images => "images") { extends "api/images/attributes" }
child(:tags => "tags") { extends "api/tags/attributes" }
