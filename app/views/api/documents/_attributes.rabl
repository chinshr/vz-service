child(:track => "track") { extends "api/tracks/attributes" }
child(:images => "images") { extends "api/images/attributes" }

attributes :id, :title, :description, :html, :rich_text, :text, :uid, :tag_list, :locale, :privacy, :accessibility, :slug_id, :slug, :published_path, :published_at, :status