child(:images => "images") { extends "api/images/attributes" }
child(:tags => "tags") { extends "api/tags/attributes" }
attributes :id, :title, :description, :uid, :tag_list, :locale, :privacy, :accessibility, :slug_id, :slug, :published_path, :published_at, :status
