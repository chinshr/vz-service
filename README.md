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
* Device with Rails 4
  - Installation flow: http://stackoverflow.com/questions/16513066/devise-with-rails-4
  - Email only signup: https://github.com/plataformatec/devise/wiki/How-To:-Email-only-sign-up
* HTML5 Editors
  - List of editors: http://www.jquery4u.com/plugins/html5-wysiwyg/  
  - Raptor Editor: https://www.raptor-editor.com
  - Save REST with Raptor: https://www.raptor-editor.com/documentation/tutorials/save-rest
* Installing ffmpeg on heroku
  - Install multi build packs: https://github.com/ddollar/heroku-buildpack-multi
  - add .buildpacks file
    https://github.com/shunjikonishi/heroku-buildpack-ffmpeg
    https://github.com/heroku/heroku-buildpack-ruby
* HTML5 Players
  - SoundManager2 (Soundcloud) http://www.schillmania.com/projects/soundmanager2/
  - jplayer.org
  - audio.js -- http://kolber.github.io/audiojs/
* Accept Incoming Emails into a Heroku App Using SendGrid 
  - http://nanceskitchen.com/2010/02/21/accept-incoming-emails-into-a-heroku-app-using-sendgrid/
  - inbound parse hooks -- http://sendgrid.com/docs/API_Reference/Webhooks/parse.html

Reference Services
------------------

* Popuparchive -- https://www.popuparchive.org
* Transcription service -- https://transcribe.wreally.com
* Oyez.org 
  - http://www.oyez.org/
  - http://www.oyez.org/cases/2000-2009/2009/2009_132ORIG 
  
Home Page Text
--------------

++++++++++
Sería muy parecido, con este texto al inicio:
Por un mayor acceso a la información, por más transparencia
Comparte los audios de tus grabaciones periodísticas

Los iconos tendrían estos textos

Figura 1
Sube tu audio

Figura 2
El sistema lo transcribe por ti

Figura 3
Edítalo

Figura 4
Compártelo

Y abajo, al final, estarían los tres últimos audios publicados. 

++++++++++++++++

Speech Transcription
--------------------

    require "speech"
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav")
    audio = Speech::AudioToText.new("samples/SampleAudio.wav")
    audio.to_json(2, "en-US")
    audio.to_text(2, "en-US")


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


