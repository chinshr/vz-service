extends "api/documents/attributes"

child(:track => "track") { extends "api/tracks/attributes" }
child(:images => "images") { extends "api/images/attributes" }

attributes :html, :rich_text, :text
