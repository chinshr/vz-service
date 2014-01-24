README
======

Development Resources
---------------------

* Bootstrap templates -- http://bootply.com/templates
* Google+ boostrap theme repo 
  - https://github.com/iatek/bootstrap-google-plus
* File uploader Backbone + S3
  - http://micahroberson.com/upload-files-directly-to-s3-w-backbone-on-heroku/
* File uploader in iFrame
* Backbone.js uploader tutorial
  - http://blog.crowdint.com/2013/02/19/how-to-manage-file-uploads-with-backbone-js-paperclip-jquery-file-upload-and.html
* Upload images: 
  - https://s.ytimg.com/yts/img/upload/large-upload-hover-icon-vflcwlQhZ.png
  - https://s.ytimg.com/yts/img/upload/large-upload-resting-icon-vflM6eC13.png
* jQuery Tag entries: 
  - http://stackoverflow.com/questions/519107/jquery-autocomplete-tagging-plug-in-like-stackoverflows-input-tags
* Backbone JS form serialization:
  - https://github.com/marioizquierdo/jquery.serializeJSON
  - http://lostechies.com/derickbailey/2011/07/24/awesome-model-binding-for-backbone-js/
  - https://github.com/theironcook/Backbone.ModelBinder
  - https://github.com/thedersen/backbone.validation
  - https://gist.github.com/driehle/2909552 -- validation with bootstrap tooltips

Speech Transcription
--------------------

    require "speech"
    audio = Speech::AudioToText.new("samples/MARTINEZ_FugaDelCabildo_RADIO.mp3")
    audio.to_text(2, "es-AR")


S3 Bucket Config
----------------

    <?xml version="1.0" encoding="UTF-8"?>
    <CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <CORSRule>
            <AllowedOrigin>*</AllowedOrigin>
            <AllowedMethod>PUT</AllowedMethod>
            <AllowedMethod>POST</AllowedMethod>
            <MaxAgeSeconds>3000</MaxAgeSeconds>
            <AllowedHeader>Content-Type</AllowedHeader>
            <AllowedHeader>x-amz-acl</AllowedHeader>
            <AllowedHeader>origin</AllowedHeader>
            <AllowedHeader>*</AllowedHeader>
        </CORSRule>
    </CORSConfiguration>


Data

- Locale, e.g. "AR-es", "US-en"
- Country of Origin 
- Categories: "Policts", "Technology", "Sports", "Art", "Literatura"
- Tags 
- Name of document and description
- Dates: Upload date, Exact date, Aproximate date
- Privacy settings: public, private, semi-private (unlisted)

Homepage

- Sort by popular
- Ranking (5 stars)
- 

Humanize in CC:

    @file_name.split(".")[0].replace(/[_-]/g, ' ').replace /(\w+)/g, match ->
      match.charAt(0).toUpperCase() + match.slice(1)


