extends "api/uploads/attributes"
attributes :metadata
child(:images => "images") { extends "api/images/attributes" }
