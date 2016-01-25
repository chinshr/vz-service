[ ![Codeship Status for vzo/vz-service](https://codeship.com/projects/2b91edd0-fd6c-0132-627a-46b29513b11c/status?branch=master)](https://codeship.com/projects/87798)

# VOYZ.ES Service

The service runs the Website and API.

# Installation

* Install bundles `bundle install`

* Migrate database `rake db:migrate` (after`rake db:create`)

* Create seeds `rake db:seed`

* Create SQS queues `rake sqs:queues:create`

## Deploy

After deployment to Heroku `git push heroku master`, the following tasks should be run:

Create SQS queues for

    rake sqs:queues:create

Regenerate slugs after changing `slug_id`:

    rake document:slugs:set_default

Update roles for all users:

    rake user:roles:set_default

Set default username from email address:

    rake user:username:set_default

## Business Resources

* Competitive products:
  - Gridspace -- http://gridspace.com
  - Transcribe Wreally -- http://transcribe.wreally.com
  - ASU Oral History Project -- http://gaialab.asu.edu/OHP
  - Hearing Aid -- http://www.transcense.com
  - Not a competitor but a great conversion tool -- cloudconvert.org
* HIPAA compliance (box notes is): http://en.wikipedia.org/wiki/Health_Insurance_Portability_and_Accountability_Act
* Dictaphone ebay buying guide -- http://www.ebay.com/gds/Dictaphone-Buying-Guide-/10000000177630514/g.html
* [OTranscribe](otranscribe.com), open source transcrition helping tool
* [Mobile Justice](https://www.mobilejusticeca.org) app
  - Article: http://www.theatlantic.com/technology/archive/2015/05/film-the-police/392483/
* [MeMini](http://memini.com) Record your life with a camera
* [ClibMine](https://clip.mn), video captions, table of contents, annotations
* [Koemei](https://koemei.com/), automatic video transcriptions and analysis, sentiment detection, etc.
* [Speechmatics](speechmatics.com/about) licensing to VoiceBase, Tony Robinson, CTO, 30+ years in ASR experience
* [Loopcast](http://beta.loopcast.fm) Audio streaming service with the UI for tiles and players I really like.
* [Clammr](https://www.clammr.com/app/) Audio podcast experience

## Patentable Ideas

Should file a "Provisional Patent" i.e. a [Provisional Patent Application](http://www.ipwatchdog.com/2013/09/14/the-benefits-of-a-provisional-patent-application/id=45156/) with the USPTO, ~$130 fees. Protected as "Patent Pending" for up to 12 months after filing.

1. Invention: "System for processing and improving speech-to-text transcripts with a hybrid machine and human approach."

Similar to:

* [System for organizing videos based on closed-caption information](https://patents.google.com/patent/US6580437B1/en?q=system&q=automatic&q=improvement&q=speech&q=to&q=text&q=transcription&q=hybrid&q=machine&q=human+approach)

* [Human-augmented, automatic speech recognition engine](https://patents.google.com/patent/US20020152071A1/en?q=system&q=automatic&q=improvement&q=speech&q=to&q=text&q=transcription&q=hybrid&q=machine&q=human+approach)

2. Invention: "Apparatus for interposing multi-media content with annotated text excerpts."

## Developer Resources

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
  - Another wysiwyg editor http://mindmup.github.io/bootstrap-wysiwyg/
  - Raptor Editor: https://www.raptor-editor.com
  - Save REST with Raptor: https://www.raptor-editor.com/documentation/tutorials/save-rest
  - Quill Rich Text Editor -- http://quilljs.com
  - Bootstrap editor -- http://mindmup.github.io/bootstrap-wysiwyg/
  - WYSIHTML5 editor -- http://customer.io/blog/Email-wysiwyg-editor-inspired-by-jekyll.html
  - Summernote editor on bootstrap -- http://hackerwins.github.io/summernote/
  - Hallo contentEditable editor -- https://github.com/bergie/hallo
* Installing ffmpeg on heroku
  - Install multi build packs: https://github.com/ddollar/heroku-buildpack-multi
  - add .buildpacks file
    https://github.com/shunjikonishi/heroku-buildpack-ffmpeg
    https://github.com/heroku/heroku-buildpack-ruby
  - Creating a build pack -- https://sendgrid.com/blog/create-first-heroku-buildpack/
* HTML5 Players
  - SoundManager2 (Soundcloud) http://www.schillmania.com/projects/soundmanager2/
  - jplayer.org
  - audio.js -- http://kolber.github.io/audiojs/
  - audio visualization -- http://www.smartjava.org/content/exploring-html5-web-audio-visualizing-sound
  - Audio Player – Responsive & Touch-Friendly -- http://tympanus.net/Development/AudioPlayer/
  - Waveform player, $6 -- http://codecanyon.net/item/zoomsounds-neat-html5-audio-player/4525354
  - Zoomsound continued, themes: http://dzsthemes.net/audioplayer/
  - Wavesurfer -- https://github.com/katspaugh/wavesurfer.js
  - Wavesurfer copy, cut, paste - http://stackoverflow.com/questions/24551854/cut-and-paste-audio-using-web-audio-api-and-wavesurfer-js
  - 60 best media players -- http://www.jqueryrain.com/example/jquery-media-player/page/5/
  - Top Ten players -- http://www.scratchinginfo.com/top-10-best-html5-audio-players/
  - UbaPlayer with Flash Fallback -- http://www.jqueryrain.com/?W1oH_b8d
  - jWebAudio with effects/gaming -- http://01org.github.io/jWebAudio/
  - Skinnable browser+audio -- http://mediaelementjs.com/
  - Build your own tutorial: http://www.alexkatz.me/html5-audio/building-a-custom-html5-audio-player-with-javascript/
  - Drawing wave forms from audio stream -- http://stackoverflow.com/questions/19536909/soundcloud-modify-the-waveform-color/19554141#19554141
* Accept Incoming Emails into a Heroku App Using SendGrid
  - ruby processor -- http://nanceskitchen.com/2010/02/21/accept-incoming-emails-into-a-heroku-app-using-sendgrid/
  - test sendgrid parse api by sending email to: my@app21958309.bymail.in (<any-address>@<sendgrid-user-name>.bymail.in)
  - griddler gem tutorial to receive emails -- http://sendgrid.com/blog/receiving-email-in-your-rails-app-with-griddler/
  - griddler gem -- https://github.com/thoughtbot/griddler
  - inbound parse hooks -- http://sendgrid.com/docs/API_Reference/Webhooks/parse.html
  - downloading attachments -- http://www.sitepoint.com/handle-incoming-email-with-sendgrid/
  - reading attachments with read in ruby -- http://stackoverflow.com/questions/11117698/receiving-emails-with-attachments-from-sendgrid-in-rails-3-2-x
  - Removing a channel http://superuser.com/questions/442562/need-to-split-stereo-track-discard-right-channel-and-remove-noise
* Capturing Audio & Video HTML5 -- http://www.html5rocks.com/en/tutorials/getusermedia/intro/
* Client side validation, simple form, rails 4 -- http://www.ddarrensmith.com/blog/2012/05/17/ruby-on-rails-client-side-validation-with-validation-helpers-and-twitter-bootstrap/
* Backbone Devise app -- https://github.com/jhuckabee/backbone_devise
* Google Speech API,
  - Languages -- http://stackoverflow.com/questions/14257598/what-are-language-codes-for-voice-recognition-languages-in-chromes-implementati
  - API keys -- http://www.chromium.org/developers/how-tos/api-keys
  - Speech API Gem v2 - https://github.com/gillesdemey/google-speech-v2/
  - Chrome speech recognition -- http://stackoverflow.com/questions/4361826/does-chrome-have-built-in-speech-recognition-for-x-webkit-speech-input-element
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
* S3 Download / Streaming
  - How to store data in S3 and allow user access in a secure way -- http://stackoverflow.com/questions/10811017/how-to-store-data-in-s3-and-allow-user-access-in-a-secure-way-with-rails-api-i
  - Nice writup using paperclip providing authorized S3 URLs: http://thewebfellas.com/blog/2009/8/29/protecting-your-paperclip-downloads
* Resources for doing noise reduction in speech -- http://www1.icsi.berkeley.edu/Speech/papers/gelbart-ms/pointers/
  - Aurora front-end archive, voice detection, noise reduction http://www1.icsi.berkeley.edu/Speech/papers/qio/
  - Convert audio to header less PCM http://stackoverflow.com/questions/4854513/can-ffmpeg-convert-audio-to-raw-pcm-if-so-how
  - Creating buildpack binaries -- http://blog.clearideas.ca/2013/04/26/Adding-Custom-Binaries-to-Heroku/
  - Vulcan configure -- http://www.higherorderheroku.com/articles/using-vulcan-to-build-binary-dependencies-on-heroku/
* Steps to create a heroku buildpack
  - curl on Heroku bash from github repo: curl -L https://github.com/chinshr/qio/tarball/master | tar zx
  - Tar and GZ the archive: tar -zcvf qio.tar.gz qio-build
* ATT Speech Service
  - Sample apps: https://github.com/attdevsupport/ATT_APIPlatform_SampleApps
  - Ruby Gist: https://gist.github.com/t2-support-gists/5189859
  - Speech Docs -- https://developer.att.com/apis/speech/docs
* List of Voice Recognition Software
  - Accurate list of speech services -- http://stackoverflow.com/questions/3113864/server-side-voice-recognition
  - Avios list of  for speech recognition tools -- http://www.avios.org/app_dev.htm
  - Wikipedia list of speech recognition tools -- http://en.wikipedia.org/wiki/List_of_speech_recognition_software
  - Nuance Dev program -- www.ndevmobile.com
  - Tropo (Voxeo) tool TTS and ASR -- https://www.tropo.com
* Nice simple and clean UI example -- https://www.firebase.com
* Another example of a great clean footer
* Ruby language tools:
  - Ruby english language tagger -- https://github.com/yohasebe/engtagger
  - Perl Lingua::DE::Tagger -- http://search.cpan.org/~tschulz/FreeHAL-71/Lingua/DE/Tagger.pm
  - Multi language tree tagger Ruby -- https://github.com/arbox/treetagger-ruby and http://search.cpan.org/dist/Lingua-TreeTagger/lib/Lingua/TreeTagger.pm
  - Ruby wordnet: https://github.com/ged/ruby-wordnet
  - Text similarity Perl library: http://sourceforge.net/projects/text-similarity/
  - Ruby similarity: https://github.com/bbcrd/Similarity
  - Hypernym distance: http://stats.stackexchange.com/questions/7313/closest-distance-in-hypernym-tree-as-measure-of-semantic-distance-between-phrase
  - Semantic similarity measurement: http://www.codeproject.com/Articles/11835/WordNet-based-semantic-similarity-measurement
  - WordNet sense similarity with NLTK: some basics -- http://jaganadhg.freeflux.net/blog/archive/2010/10/19/wordnet-sense-similarity-with-nltk-some-basics.html
  - Fuzzy match ruby library, https://github.com/seamusabshere/fuzzy_match
  - Fuzzy match using Sørensen–Dice coefficient http://en.wikipedia.org/wiki/Sørensen–Dice_coefficient
  - Bag-of words model for utterance similarity -- http://en.wikipedia.org/wiki/Bag_of_words_model
* Sentence correction with Ginger http://www.gingersoftware.com
  - https://github.com/subosito/gingerice
* Parallax effects with bootstrap
  - https://wrapbootstrap.com/tag/parallax
* Awesome icons -- http://fortawesome.github.io/Font-Awesome/icons/
* Flipping DIVs in HTML5 tutorial: http://simonlockyer.info/flip-div-css3-tutorial/
* Gmail inbox grid
  - http://www.bootply.com/XXmcPas41w
* SQL to select groups: http://stackoverflow.com/questions/3800551/select-first-row-in-each-group-by-group
* Kaldi speech engine, open source -- http://kaldi.sourceforge.net
* Machine learning
  - Data analysis -- http://deepdive.stanford.edu
  - Conditional Random Fields (CRF) models, e.g. DeepDive, Tuffy
  - SK Learn -- http://scikit-learn.org/stable/
  - Support Vector Machine (SVM)
  - Jaccard Coefficient
  - Machine learning gem AI4R, SciRuby,
  - Machine learning for everyone: BigML.com, kaggle.com
* Create ICO file from PNG -- http://stackoverflow.com/questions/4584895/favicon-to-png-in-php
* Bootstrap Youtube modal -- http://lab.abhinayrathore.com/bootstrap-youtube/
* Convert png to icons (ico) for favicon http://iconverticons.com/
* Retina images -- https://github.com/imulus/retinajs
* Bootstrap resources
  - Another amazing bootstrap home page theme -- http://themify.me/demo/themes/fullpane/
  - Bootstrap modal manager and fix for responsive layouts -- https://github.com/jschr/bootstrap-modal
  - Alternatives bootstrap checkbox -- http://montrezorro.github.io/bootstrap-checkbox/
  - Dropdown select with lookahead and tagging -- http://ivaynberg.github.io/select2/
  - Bootstrap Combobox -- https://github.com/danielfarrell/bootstrap-combobox
  - FuelUX, http://exacttarget.github.io/fuelux/
  - Login from navbar dropdown -- http://mifsud.me/adding-dropdown-login-form-bootstraps-navbar/
  - Twitter radio buttons from input http://dan.doezema.com/2012/03/twitter-bootstrap-radio-button-form-inputs/
  - File input with image -- http://jasny.github.io/bootstrap/javascript/#fileinput
  - Bootstrap Dropbox uploader -- http://tutorialzine.com/2012/11/dropbox-photo-crop/
  - Cropper, image cropping with jQuery -- https://github.com/fengyuanchen/cropper
  - HTML5 image uploader with crop -- http://www.script-tutorials.com/html5-image-uploader-with-jcrop/
  - Image upload and crop -- http://www.jqueryrain.com/demo/jquery-crop-image-plugin/
  - Chosen, better select/combo -- http://harvesthq.github.io/chosen/
  - Yet another combo, select, tag input: http://brianreavis.github.io/selectize.js/
* typeahead.js provides search suggestions -- http://twitter.github.io/typeahead.js
* JS injecting extra info to copy-pasted text -- http://www.jitbit.com/alexblog/230-javascript-injecting-extra-info-to-copy-pasted-text/
* Adapting to retina display -- http://www.sitepoint.com/css-techniques-for-retina-displays/
* Mobile app development, PhoneGap recording samples:
  - https://software.intel.com/en-us/html5/articles/media-sample-with-phonegap
  - Samples app repo: https://github.com/gomobile/sample-phonegap-audio
  - PhoneGap audio example: https://github.com/bargar/phone-gap-audio-example
  - http://docs.phonegap.com/en/3.3.0/cordova_media_media.md.html#Media
  - Build apps with phonegap famous book -- https://www.gitbook.io/book/nicholasareed/playbook-to-build-apps-with-phonegap-famous
* Standards Terms -- http://www.entrepreneur.com/formnet/form/1174
* Video player for cover background videos -- https://github.com/stefanerickson/covervid
* Live updating with Rails:
  - Faye implementation tutorial -- http://code.tutsplus.com/tutorials/how-to-use-faye-as-a-real-time-push-server-in-rails--net-22600
  - Faye example app on heroku -- https://github.com/ntenisOT/Faye-Heroku-Cedar-RedisToGo
  - ActionController::Live, see online resources
  - Adding real time to Rails w/ WebSockets and http://liamkaufman.com/blog/2013/02/27/adding-real-time-to-a-restful-rails-app/
  - Real time rails w/ node.js-- http://mikeatlas.github.io/realtime-rails/
  - Pusher Rails on Heroku example -- https://github.com/phuphighter/pusher_app_example
* Speex, speech codec with voice activation (VAD), echo cancellation -- http://www.speex.org/docs/manual/speex-manual/node4.html#SECTION00420000000000000000
* Opus Codec, successor of Speex, w/ Skype contributions, noise reduction, noise filter:
  - Opus voice paper http://jmvalin.ca/papers/aes135_opus_silk.pdf
* Codepen for Quill bug -- http://codepen.io/anon/pen/GCIku
* Devise API authentication
  - https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
  - Example apps for devise including one for API auth
  - http://stackoverflow.com/questions/6021372/best-way-to-create-unique-token-in-rails
* API code documentation
  - Hints on Stripe's API doc: http://www.quora.com/Stripe-company/What-software-powers-the-Stripe-API-documentation
  - Beautiful API documentation w/ Slate: https://github.com/tripit/slate
* API responders to customize respond_with
  - Responders for API versioning
  - ActionController::Responder -- http://weblog.rubyonrails.org/2009/8/31/three-reasons-love-responder/
  - Customer responders -- http://archives.ryandaigle.com/articles/2009/8/10/what-s-new-in-edge-rails-default-restful-rendering
  - respond_with(@product, :responder => MyResponder)
  - default Rails responder class source -- https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/metal/responder.rb
  - Responders gem -- https://github.com/plataformatec/responders
  - Customize responder in Devise w/ FailureApp -- https://github.com/plataformatec/devise/wiki/How-To:-Redirect-to-a-specific-page-when-the-user-can-not-be-authenticated
* Download Video/Audio from YouTube, DailyMotion, etc. -- https://github.com/rb2k/viddl-rb
  - youtube-dl better python script, more than 100 of sites -- http://rg3.github.io/youtube-dl/
* HTML5 rotation
  - Flip rotate HTML5 elements with JS plugin: http://lab.smashup.it/flip/
  - CSS3 rotation -- http://davidwalsh.name/css-flip
  - CSS3 animation events -- http://www.sitepoint.com/css3-animation-javascript-event-handlers/
* Installing CMU Sphinx
  - Ruby Pocketsphinx server -- https://github.com/alumae/ruby-pocketsphinx-server
  - Ruby Pocketsphinx gem -- https://github.com/watsonbox/pocketsphinx-ruby
  - Another Sinatra Pocketsphinx project -- https://github.com/janika/sinatra_speech
  - Speech Recognizer -- https://github.com/alumae/speech_recognizer
  - Install Sphinx and Pocketsphinx -- https://mattze96.safe-ws.de/blog/?p=640
  - GST Speech API -- https://github.com/alumae/GST-Speech-API
* Customer interaction and customer messaging, that codeship uses -- www.intercom.io
* Open source iOS apps -- https://github.com/dkhamsing/open-source-ios-apps
* Using Mechanical Turk with Ruby
  - Turkee: http://rubysnippets.com/2012/11/19/using-mechanical-turk-in-your-rails-app/
* Avatar uploading, cropping, S3:
  - Carrierwave direct to S3 -- https://github.com/dwilkie/carrierwave_direct
  - Rails Demo app with Carrierwave, S3, [jCrop](https://github.com/n0ne/Rails-Carrierwave-jQuery-File-Upload)
  - Working jQuery-file-upload with demo -- https://github.com/blueimp/jQuery-File-Upload
* Transition browser compatibility -- http://www.sitepoint.com/css3-animation-javascript-event-handlers/
* Pinterest layout for Dashboard with Bootstrap
  - [Wookmark jQuery library](https://github.com/germanysbestkeptsecret/Wookmark-jQuery)
  - [Pinterest layout demo](http://bragthemes.com/demo/pinstrap/) based on [Wookmark jQuery library](https://github.com/germanysbestkeptsecret/Wookmark-jQuery)
* EC2 instance setup
  - Run command each time an [EC2 instance boots](http://serverfault.com/questions/369872/run-a-bash-script-after-ec2-instance-boots)
  - [User Data Scripts](https://alestic.com/2009/06/ec2-user-data-scripts/)
  - Ruby AWS [user data example](https://github.com/aws/aws-sdk-ruby/issues/191)
* Canvas video, instead of video element, use sprite -- https://github.com/gka/canvid
* Backbone + PubNub
  - [Tutorial](https://cdnjs.com/libraries/backbone.js/tutorials/real-time-backbone-with-pubnub/)
* Real-time editors and implementation
  - [Real-time Text Editor using Pubnub+Modulus, Part 1](http://blog.modulus.io/distributed-real-time-text-editor)
  - [Real-time Text Editor using Pubnub+Modulus, Part 2](http://blog.modulus.io/pub-nub-and-modulus-part-2)
  -  [PubNub presence](https://www.pubnub.com/docs/web-javascript/presence)
  - [Firebase Firepad on GitHub](https://github.com/firebase/firepad) and [Live Demo](https://demo.firepad.io/#sxz0Ct8eko)
* Layout of audio
  - Clammr - to get idea about index page tiles https://www.clammr.com/app/
  - http://beta.loopcast.fm
* Serving static file, e.g. from action/controller
  - [Use redirect on Heroku](http://stackoverflow.com/questions/6307135/alternative-to-x-sendfile-on-heroku)
  - [Rack:SendFile not supported on Heroku](https://devcenter.heroku.com/articles/rack-sendfile)
  - [No workarounds on Heroku](https://groups.google.com/forum/#!topic/heroku/xr71eYDFgo4)

### SendGrid Setup

app21958309.bymail.in -> http://voyzes.herokuapp.com/endpoints/receive_email.xml
my@voyz.es -> http://voyzes.herokuapp.com/endpoints/receive_email.xml

app21958309.bymail.in -> http://voyzes.herokuapp.com/email_processor.xml
my.voyz.es -> http://voyzes.herokuapp.com/email_processor.xml

### Reference Services

* Popuparchive -- https://www.popuparchive.org
* Transcription service -- https://transcribe.wreally.com
* Oyez.org
  - http://www.oyez.org/
  - http://www.oyez.org/cases/2000-2009/2009/2009_132ORIG
* Nuance has a voice to text service -- http://www.nuance.com/for-business/mobile-solutions/voice-to-text-services/index.htm
  - contact: Bill Sheppard, bill.sheppard@nuance.com, 408.242.8177

### Home Page

Images:

* Home hero shot -- http://www.flickr.com/photos/bkhl/5670222339/

* Upload Audio -- http://www.flickr.com/photos/stevegibbs/7709749172

* Transcribe --

* Share -- http://www.flickr.com/photos/royprasad/4714980030

* Icon
  - http://www.flickr.com/photos/36218298
  - http://www.flickr.com/photos/82038674

Sería muy parecido, con este texto al inicio:

Por un mayor acceso a la información, por más transparencia
Comparte los audios de tus grabaciones periodísticas

Los iconos tendrían estos textos

```
Figura 1
Sube tu audio

Figura 2
El sistema lo transcribe por ti

Figura 3
Edítalo

Figura 4
Compártelo

Y abajo, al final, estarían los tres últimos audios publicados.
```

### Voice Profiles

Meeting room
Conference
Street
Coffee Shop
Car
Telephone
Television

### Speech Transcription

    require "speech"
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav")
    audio = Speech::AudioToText.new("samples/SampleAudio.wav")
    audio = Speech::AudioToText.new("samples/New-Recording.m4a")
    audio = Speech::AudioToText.new("samples/cleaned.wav")
    audio.to_json(:max_results => 2, :locale => "en-US")
    audio.to_text(:max_results => 2, :locale => "en-US")

    # Pocketsphinx Server V1
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :verbose => true, :engine => :pocketsphinx_server_engine); audio.to_json

    # Google V1 Chromium Engine
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :verbose => true, :engine => :google_speech_engine, :version => "v1"); audio.to_json

    # Google V2 Speech Engine
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :verbose => true, :engine => :google_speech_engine, :version => "v2", :key => "AIzaSyAqcAyKz-aQq-LWSrAYkajCbqRQflTLCKY"); audio.to_json
    audio = Speech::AudioToText.new("samples/me-gusta-pepinillos.m4a", :verbose => true); audio.to_json(:locale => "es-MX")

    # ATT Speech Engine, mode: standard
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", :mode => "standard", :verbose => true); audio.to_json

    audio = Speech::AudioToText.new("samples/me-gusta-pepinillos.m4a", :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", :mode => "standard", :verbose => true); audio.to_json(:locale => "es-MX")

    # ATT Speech Engine, mode: custom
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", :mode => "custom", :verbose => true)

    # Nuance Dragon Engine
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :engine => :nuance_dragon_engine, :verbose => true, :base_url => "https://dictation.nuancemobility.net:443", :app_id => "NMDPTRIAL_chinshr20140326185635", :app_key => "edb1acb2e50d02417b643e6dce510ea9dd565c4ad4725dcb8d807c96fe6304eb14b09ef9bea03a390578a6d3cab57ca70bd8f1df4b4eabd8cf276ecd8a72b99f&id=C4461956B60B"); audio.to_json

    audio = Speech::AudioToText.new("samples/me-gusta-pepinillos.m4a", :engine => :nuance_dragon_engine, :verbose => true, :base_url => "https://dictation.nuancemobility.net:443", :app_id => "NMDPTRIAL_chinshr20140326185635", :app_key => "edb1acb2e50d02417b643e6dce510ea9dd565c4ad4725dcb8d807c96fe6304eb14b09ef9bea03a390578a6d3cab57ca70bd8f1df4b4eabd8cf276ecd8a72b99f&id=C4461956B60B"); audio.to_json(:locale => "es-MX")

### Best transcription

require "fuzzy_match"
z[0] = "where should we there yet the voice of Nemo 2700 this recording right to know that I'm f****** over here we can do that this has been a way or the other"
z[1] = "Voice app. Boarding. I'm talking to it."
z[2] = "Is requesting the voicesIs requesting the voices right This recording serviceAnd this recording service I'm talking to CaseyI'm talking to season"
a = z.each_index.inject([]) do |column, column_index|
  column << z.each_index.inject([]) do |row, row_index|
    row << z[column_index].levenshtein_similar(z[row_index])
  end
end
m=Matrix.rows(a)
total_words = z.inject(0) {|r, e| r += e.split.size}
v=m * Vector[z[0].split.size / total_words.to_f, z[1].split.size / total_words.to_f, z[2].split.size / total_words.to_f]
=> Vector[1.4473684210526316, 1.3647912885662432, 1.4963702359346642]

### Nuance NDEV Developer Program, Dragon Mobile, ASR and TTS

http://dragonmobile.nuancemobiledeveloper.com

Development Keys:
Package: /Users/juergen/Downloads/ndev/Samples/Java ASRHTTPClient

Host: sandbox.nmdp.nuancemobility.net
Port: 443
AppID: NMDPTRIAL_chinshr20140326185635
AppKey:	0xed 0xb1 0xac 0xb2 0xe5 0x0d 0x02 0x41 0x7b 0x64 0x3e 0x6d 0xce 0x51 0x0e 0xa9 0xdd 0x56 0x5c 0x4a 0xd4 0x72 0x5d 0xcb 0x8d 0x80 0x7c 0x96 0xfe 0x63 0x04 0xeb 0x14 0xb0 0x9e 0xf9 0xbe 0xa0 0x3a 0x39 0x05 0x78 0xa6 0xd3 0xca 0xb5 0x7c 0xa7 0x0b 0xd8 0xf1 0xdf 0x4b 0x4e 0xab 0xd8 0xcf 0x27 0x6e 0xcd 0x8a 0x72 0xb9 0x9f
128-Byte String Version of your AppKey: edb1acb2e50d02417b643e6dce510ea9dd565c4ad4725dcb8d807c96fe6304eb14b09ef9bea03a390578a6d3cab57ca70bd8f1df4b4eabd8cf276ecd8a72b99f


Production Keys:

  Host: blb.nmdp.nuancemobility.net
  Port: 443
  AppID: NMDPPRODUCTION_Voyzes_Voyzes_20140327191536
  AppKey: 0x10 0x0f 0xd1 0xa6 0xf8 0xf7 0x24 0x51 0xad 0xdd 0x30 0x65 0xbb 0x40 0xc5 0x21 0xfb 0x36 0xca 0x2e 0x92 0xd4 0x93 0xcb 0xbd 0x0b 0xad 0x71 0x00 0xc8 0xdd 0x10 0xd8 0xae 0xb7 0xd0 0xa6 0xdb 0x21 0x53 0xb9 0x52 0xb8 0x74 0x92 0x7d 0x95 0x8d 0xb4 0x5f 0xbb 0x46 0x33 0x4e 0x11 0xf0 0x5a 0xbe 0x61 0x5a 0x86 0x3e 0x6b 0x5e

### S3 Bucket Config

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


### Requirements + Notes

- Locale, e.g. "AR-es", "US-en"
- Country of Origin
- Categories: "Politics", "Technology", "Sports", "Art", "Literatura"
- Tags
- Name of document and description
- Dates: Upload date, Exact date, Aproximate date
- Privacy settings: public, private, semi-private (unlisted)


### Humanize Gist

    @file_name.split(".")[0].replace(/[_-]/g, ' ').replace /(\w+)/g, match ->
      match.charAt(0).toUpperCase() + match.slice(1)

### SoX Audio noise reduction pipeline

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

### Standard SOX normalizer

    sox john-and-juergen.wav john-and-juergen.cleaned.wav \
      remix - \
      highpass 100 \
      norm \
      compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \
      vad -T 0.6 -p 0.2 -t 5 \
      fade 0.1 \
      reverse \
      vad -T 0.6 -p 0.2 -t 5 \
      fade 0.1 \
      reverse \
      norm -0.5

### Aurora QIO pipeline

Setup env

    export AURORACALC=/Users/juergen/Downloads/aurora-front-end/qio
    export PATH=$PATH:$AURORACALC/src

Get a list of supported PCM formats:

    ffmpeg -formats | grep PCM

Convert audio to Wav format:

   ffmpeg -i john-and-juergen.m4a -y -f wav -ac 2 john-and-juergen.wav

Convert to raw headerless PCM and down sample to 16-bit

    ffmpeg -i john-and-juergen.wav -ar 16000 -y -f s16le -acodec pcm_s16le john-and-juergen.pcm

Create silence flags, 25ms window, without Wiener filter:

    silence_flags -S 0 -Length 25 \
      -VADweights $AURORACALC/parameters/vad/net.tim-fin-tic-spn-rand.54i+50h+2o.mel-delay+dct+lpf.wts.head \
      -VADnorm $AURORACALC/parameters/vad/tim-fin-tic-spn-rand.mel-delay+dct+lpf.norms \
      -fs 16000 -swapin 0 \
      -i john-and-juergen.pcm -o john-and-juergen.s

Create silence flags, 25ms window, including Wiener filter:

    silence_flags -S 1 -Length 25 \
      -VADweights $AURORACALC/parameters/vad/net.tim-fin-tic-it-spn-rand.54i+50h+2o.0-delay-wiener+dct+lpf.wts.head \
      -VADnorm $AURORACALC/parameters/vad/tim-fin-tic-it-spn-rand.0-delay-wiener+dct+lpf.norms \
      -fs 16000 -swapin 0 \
      -i john-and-juergen.pcm -o john-and-juergen.s

Create silence flags, 20ms window no Wiener:

    silence_flags -S 0 -Length 20 \
      -VADweights $AURORACALC/parameters/vad/net.tim-fin-tic-spn-rand.54i+50h+2o.win20-mel-delay+dct+lpf.wts.head \
      -VADnorm $AURORACALC/parameters/vad/tim-fin-tic-spn-rand.win20-mel-delay+dct+lpf.norms \
      -fs 16000 -swapin 0 \
      -i john-and-juergen.pcm -o john-and-juergen.s

Noise reduce PCM file with silence flags:

    nr -fs 16000 -Length 20 -swapin 0 -swapout 0 \
      -Ssilfile john-and-juergen.s \
      -i john-and-juergen.pcm -o john-and-juergen.cleaned.pcm

Convert PCM file back to wav audio:

    ffmpeg -f s16le -ar 16k -ac 2 -y -i john-and-juergen.cleaned.pcm john-and-juergen.cleaned.wav

Let's normalize afterwards:

    sox john-and-juergen.cleaned.wav john-and-juergen.cleaned.normalized.wav \
      remix - \
      highpass 100\
      norm \
      compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \
      vad -T 0.6 -p 0.2 -t 5 \
      fade 0.0 \
      reverse \
      vad -T 0.6 -p 0.2 -t 5 \
      fade 0.0 \
      reverse \
      norm -0.5

Listening to TCP port 80

    sudo tcpflow -p -c -i en0 port 80 | grep -oE '(GET|POST|HEAD) .* HTTP/1.[01]|Host: .*'


### Install Pocketsphinx

#### Install

    brew install gstreamer010
    brew install gst-plugins-base010
    brew install libxml2

#### Setup

    export GST_PLUGIN_PATH=/usr/local/lib/gstreamer-0.10

Create folders

    mkdir voice_recognition; cd voice_recognition

#### Download Sphinxbase:

    cd sphinxbase

    git clone git://github.com/cmusphinx/sphinxbase.git

or

    svn co https://cmusphinx.svn.sourceforge.net/svnroot/cmusphinx/trunk/sphinxbase

Install missing libraries on Darwin:

    brew install swig
    brew install libtools

Modify autogen.sh, change `libtoolize` to `glibtoolize`

Create makefiles

    ./autogen.sh

Compile

    make

Install Sphinxbase

    sudo make install
    cd ..

Download Pocketsphinx at the `/voice_recognition` root.

    git clone git://github.com/cmusphinx/pocketsphinx.git

Generate makefiles (before executing script change `libtoolize` to `glibtoolize`)

     ./autogen.sh

Compile pocketsphinx

    make

Install pocketsphinx

    sudo make install
    cd ..

Install and extract dictionary and configure

    wget http://goofy.zamia.org/voxforge/de/voxforge-de-r20140907.tgz
    tar xvzf voxforge-de-r20140907.tgz

Change configuration to:

    cd voxforge-de-r20140907
    nano run-pocketsphinx.sh

and add this:

    pocketsphinx_continuous \
        -hmm model_parameters/voxforge.cd_cont_3000 \
        -lw 10 -feat 1s_c_d_dd -beam 1e-80 -wbeam 1e-40 \
        -dict etc/voxforge.dic \
        -wip 0.2 \
        -agc none -varnorm no -cmn current -inmic yes \
        -lm etc/voxforge.lm.DMP

Run pocketsphinx

    ./run-pocketsphinx.sh

## Genesis Recording Script

### Genesis 1-1 English in the US

In the beginning God created the heavens and the earth.
Now the earth was formless and empty, darkness was over the surface of the deep, and the Spirit of God was hovering over the waters.
And God said, “Let there be light,” and there was light.
God saw that the light was good,
and he separated the light from the darkness.
God called the light “day,” and the darkness he called “night.”
And there was evening, and there was morning—the first day.

### Genesis 1-1 German in Bavarian :-)

Im Anfang schuf Gott Himmel und Erde.
Und die Erde war wüst und leer, und es war ﬁnster auf der Tiefe;
und der Geist Gottes schwebte auf dem Wasser.
Und Gott sprach: Es werde Licht! Und es ward Licht.
Und Gott sah, dass das Licht gut war.
Da schied Gott das Licht von der Finsternis
und nannte das Licht Tag und die Finsternis Nacht.
Da ward aus Abend und Morgen der erste Tag.

### Genesis 1-1 Spanish in Argentina

En el principio creó dios los cielos y la tierra.
Y la tierra estaba desordenada y vacía, y las tinieblas estaban sobre la faz del abismo,
Y el espíritu de dios se movía sobre la faz de las aguas.
Y dijo dios: Sea la luz! Y fue la luz.
Y vio dios que la luz era buena;
Y separó dios la luz de las tinieblas.
Y llamó dios a la luz día, y a las tinieblas llamó noche.
Y fue la tarde y la mañana un día.
