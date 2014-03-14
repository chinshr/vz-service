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
  - audio visualization -- http://www.smartjava.org/content/exploring-html5-web-audio-visualizing-sound
* Accept Incoming Emails into a Heroku App Using SendGrid 
  - ruby processor -- http://nanceskitchen.com/2010/02/21/accept-incoming-emails-into-a-heroku-app-using-sendgrid/
  - test sendgrid parse api by sending email to: my@app21958309.bymail.in (<any-address>@<sendgrid-user-name>.bymail.in)
  - griddler gem tutorial to receive emails -- http://sendgrid.com/blog/receiving-email-in-your-rails-app-with-griddler/
  - griddler gem -- https://github.com/thoughtbot/griddler
  - inbound parse hooks -- http://sendgrid.com/docs/API_Reference/Webhooks/parse.html
  - downloading attachments -- http://www.sitepoint.com/handle-incoming-email-with-sendgrid/
  - reading attachments with read in ruby -- http://stackoverflow.com/questions/11117698/receiving-emails-with-attachments-from-sendgrid-in-rails-3-2-x
  - Removing a channel http://superuser.com/questions/442562/need-to-split-stereo-track-discard-right-channel-and-remove-noise
* Capturing Audio&Video HTML5 -- http://www.html5rocks.com/en/tutorials/getusermedia/intro/
* Client side validation, simple form, rails 4 -- http://www.ddarrensmith.com/blog/2012/05/17/ruby-on-rails-client-side-validation-with-validation-helpers-and-twitter-bootstrap/
* Backbone Devise app -- https://github.com/jhuckabee/backbone_devise
* Google Speech API, Languages -- http://stackoverflow.com/questions/14257598/what-are-language-codes-for-voice-recognition-languages-in-chromes-implementati
* Noise reduction 
  - with ffmpeg and sox: http://www.zoharbabin.com/how-to-do-noise-reduction-using-ffmpeg-and-sox/
  - ffmpeg: http://ffmpeg.zeranoe.com/forum/viewtopic.php?f=15&t=1687
  - Sox buildpack: https://github.com/lepinsk/heroku-buildpack-sox
  - noiseprof, noisered, and artifacts on audio -- http://sox.10957.n7.nabble.com/noiseprof-noisered-and-artifacts-on-audio-td4971.html
  - Voice Activity Detection (VAD) to detect the section of silence before the user actually starts speaking -- https://github.com/jacksonh/sox/blob/master/scripts/voice-cleanup.sh
  - Batch processing audio files with SOX -- http://www.benmcdowell.com/blog/2012/01/29/batch-processing-audio-file-cleanup-with-sox/
  - VAD engery detector -- http://stackoverflow.com/questions/5498142/what-is-a-good-approach-for-extracting-portions-of-speech-from-an-arbitrary-audi
* Convert audio to flac -- http://superuser.com/questions/339023/convert-audio-file-to-flac-with-ffmpeg
* A command line tool to slice sound files at onset or beat timestamps -- http://aubio.org/manpages/latest/aubiocut.1.html
* Extracting portion of speech -- http://stackoverflow.com/questions/5498142/what-is-a-good-approach-for-extracting-portions-of-speech-from-an-arbitrary-audi
* How to store data in S3 and allow user access in a secure way -- http://stackoverflow.com/questions/10811017/how-to-store-data-in-s3-and-allow-user-access-in-a-secure-way-with-rails-api-i


SendGrid Setup
--------------

app21958309.bymail.in -> http://voyzes.herokuapp.com/endpoints/receive_email.xml
my@voyz.es -> http://voyzes.herokuapp.com/endpoints/receive_email.xml

app21958309.bymail.in -> http://voyzes.herokuapp.com/email_processor.xml
my.voyz.es -> http://voyzes.herokuapp.com/email_processor.xml
  
Reference Services
------------------

* Popuparchive -- https://www.popuparchive.org
* Transcription service -- https://transcribe.wreally.com
* Oyez.org 
  - http://www.oyez.org/
  - http://www.oyez.org/cases/2000-2009/2009/2009_132ORIG 
* Nuance has a voice to text service -- http://www.nuance.com/for-business/mobile-solutions/voice-to-text-services/index.htm
  - contact: Bill Sheppard, bill.sheppard@nuance.com, 408.242.8177
  
Home Page
---------

Images:

* Home hero shot -- http://www.flickr.com/photos/bkhl/5670222339/

* Upload Audio -- http://www.flickr.com/photos/stevegibbs/7709749172

* Transcribe -- 

* Share -- http://www.flickr.com/photos/royprasad/4714980030

* Icon
  - http://www.flickr.com/photos/36218298
  - http://www.flickr.com/photos/82038674

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
    audio = Speech::AudioToText.new("samples/New-Recording.m4a")
    audio = Speech::AudioToText.new("samples/cleaned.wav")
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

## Audio noise reduction pipeline

Convert to wav file format:

    ffmpeg -i will-and-juergen.m4a -f wav -ac 1 will-and-juergen.wav
    ffmpeg -i john-and-juergen.m4a -f wav -ac 1 john-and-juergen.wav

We first use vad to detect the section of silence before the user actually starts speaking, using stat to output the length of the file before and after (Big thanks to whoever put the original voice-cleanup script online, it was a big help in developing this).

    sox -t raw -r 44.1k -e signed-int -c 1 -b 16 john-and-juergen.wav discard.wav \
      stat highpass 100 norm compand 0.05,0.2 6:-54,-84,-36,-36,-24,-24,0,-12 0 -84 0.2 \
      vad -T 0.25 -p 0.2 -t 5 stat

We then take that length, and generate a noiseprof from it

    sox -t raw -r 44.1k -e signed-int -c 1 -b 16 john-and-juergen.wav discard.wav trim 0 0.1 noiseprof noise.profile
    sox -t raw -r 44.1k -e signed-int -c 1 -b 16 john-and-juergen.wav discard.wav trim 1.079728 1.082533 noiseprof noise.profile
    sox -t raw -r 44.1k -e signed-int -c 1 -b 16 john-and-juergen.wav discard.wav trim 1.079728 0.001 noiseprof noise.profile

Finally, we run our full output pipeline with noisered

    sox -t raw -r 44.1k -e signed-int -c 1 -b 16 john-and-juergen.wav -C 80 cleaned.wav \
      noisered noise.profile 0.5 \
      highpass 100 norm compand 0.05,0.2 6:-54,-84,-36,-36,-24,-24,0,-12 0 -84 0.2 \
      vad -T 0.25 -p 0.2 -t 5 reverse \
      vad -T 0.25 -p 0.25 -t 5 reverse \
      norm -0.5 rate 44.1k stat

Simpler, voice cleanup from http://sox.sourceforge.net/Docs/Scripts:

    sox john-and-juergen.wav cleaned.wav \
      remix - \
      highpass 100 lowpass 2k \
      norm \
      compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \
      vad -T 0.6 -p 0.2 -t 5 \
      fade 0.1 \
      reverse \
      vad -T 0.6 -p 0.2 -t 5 \
      fade 0.1 \
      reverse \
      norm -0.5


      sox john-and-juergen.m4a cleaned.m4a \
        remix - \
        highpass 100 lowpass 2k \
        norm \
        compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \
        vad -T 0.6 -p 0.2 -t 5 \
        fade 0.1 \
        reverse \
        vad -T 0.6 -p 0.2 -t 5 \
        fade 0.1 \
        reverse \
        norm -0.5


My combined version of the two from above:

    sox -t raw -r 44.1k -e signed-int -c 1 -b 16 john-and-juergen.wav cleaned.wav \
      remix - \
      highpass 100 \
      norm \
      noisered noise.profile 0.5 \
      compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \
      vad -T 0.25 -p 0.2 -t 5 fade 0.1 reverse \
      vad -T 0.25 -p 0.25 -t 5 fade 0.1 reverse \
      norm -0.5 rate 44.1k stat

