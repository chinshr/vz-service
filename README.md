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
  - Another wysiwyg editor http://mindmup.github.io/bootstrap-wysiwyg/
  - Raptor Editor: https://www.raptor-editor.com
  - Save REST with Raptor: https://www.raptor-editor.com/documentation/tutorials/save-rest
  - Quill Rich Text Editor -- http://quilljs.com
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
  - Audio Player – Responsive & Touch-Friendly -- http://tympanus.net/Development/AudioPlayer/
  - Waveform player, $6 -- http://codecanyon.net/item/zoomsounds-neat-html5-audio-player/4525354
  - Zoomsound continued, themes: http://dzsthemes.net/audioplayer/
  - Wavesurfer -- https://github.com/katspaugh/wavesurfer.js
  - Top Ten players -- http://www.scratchinginfo.com/top-10-best-html5-audio-players/
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
* How to store data in S3 and allow user access in a secure way -- http://stackoverflow.com/questions/10811017/how-to-store-data-in-s3-and-allow-user-access-in-a-secure-way-with-rails-api-i
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
  - Pinterest layout with bootstrap -- http://bragthemes.com/demo/pinstrap/
  - Dropdown select with lookahead and tagging -- http://ivaynberg.github.io/select2/
  - Bootstrap Combobox -- https://github.com/danielfarrell/bootstrap-combobox
  - FuelUX, http://exacttarget.github.io/fuelux/
  - Login from navbar dropdown -- http://mifsud.me/adding-dropdown-login-form-bootstraps-navbar/
  - Twitter radio buttons from input http://dan.doezema.com/2012/03/twitter-bootstrap-radio-button-form-inputs/
  - File input with image -- http://jasny.github.io/bootstrap/javascript/#fileinput
  - Bootstrap Dropbox uploader -- http://tutorialzine.com/2012/11/dropbox-photo-crop/
  - HTML5 image uploader with crop -- http://www.script-tutorials.com/html5-image-uploader-with-jcrop/
  - Image upload and crop -- http://www.jqueryrain.com/demo/jquery-crop-image-plugin/
  - Chosen, better select/combo -- http://harvesthq.github.io/chosen/
  - Yet another combo, select, tag input: http://brianreavis.github.io/selectize.js/
* typeahead.js provides search suggestions -- http://twitter.github.io/typeahead.js
* JS injecting extra info to copy-pasted text -- http://www.jitbit.com/alexblog/230-javascript-injecting-extra-info-to-copy-pasted-text/

Competitive Products
--------------------

* Gridspace -- http://gridspace.com
* Transcribe Wreally -- http://transcribe.wreally.com

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

Voice Profiles
--------------

Meeting room
Conference
Street
Coffee Shop
Car
Telephone
Television

Speech Transcription
--------------------

    require "speech"
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav")
    audio = Speech::AudioToText.new("samples/SampleAudio.wav")
    audio = Speech::AudioToText.new("samples/New-Recording.m4a")
    audio = Speech::AudioToText.new("samples/cleaned.wav")
    audio.to_json(:max_results => 2, :locale => "en-US")
    audio.to_text(:max_results => 2, :locale => "en-US")
    
    # Google Speech Engine
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :verbose => true); audio.to_json
    audio = Speech::AudioToText.new("samples/me-gusta-pepinillos.m4a", :verbose => true); audio.to_json(:locale => "es-MX")

    # ATT Speech Engine, mode: standard
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", :mode => "standard", :verbose => true); audio.to_json

    audio = Speech::AudioToText.new("samples/me-gusta-pepinillos.m4a", :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", :mode => "standard", :verbose => true); audio.to_json(:locale => "es-MX")

    # ATT Speech Engine, mode: custom
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :engine => :att_speech_engine, :api_key => "tgcqoeaecj4ff052a9ee8g0mzt9xti7p", :secret_key => "j7caqnrtvtiiqhtl1nhlmyp5li0dclxg", :mode => "custom", :verbose => true)
    
    # Nuance Dragon Engine
    audio = Speech::AudioToText.new("samples/i-like-pickles.wav", :engine => :nuance_dragon_engine, :verbose => true, :base_url => "https://dictation.nuancemobility.net:443", :app_id => "NMDPTRIAL_chinshr20140326185635", :app_key => "edb1acb2e50d02417b643e6dce510ea9dd565c4ad4725dcb8d807c96fe6304eb14b09ef9bea03a390578a6d3cab57ca70bd8f1df4b4eabd8cf276ecd8a72b99f&id=C4461956B60B"); audio.to_json

    audio = Speech::AudioToText.new("samples/me-gusta-pepinillos.m4a", :engine => :nuance_dragon_engine, :verbose => true, :base_url => "https://dictation.nuancemobility.net:443", :app_id => "NMDPTRIAL_chinshr20140326185635", :app_key => "edb1acb2e50d02417b643e6dce510ea9dd565c4ad4725dcb8d807c96fe6304eb14b09ef9bea03a390578a6d3cab57ca70bd8f1df4b4eabd8cf276ecd8a72b99f&id=C4461956B60B"); audio.to_json(:locale => "es-MX")

Best transcription
------------------

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

Nuance NDEV Developer Program, Dragon Mobile, ASR and TTS
---------------------------------------------------------

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

## SoX Audio noise reduction pipeline

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

## Standard SOX normalizer

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

## Aurora QIO pipeline

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

Genesis Recording Script
========================

Genesis 1-1 English in the US
-----------------------------

In the beginning God created the heavens and the earth. 
Now the earth was formless and empty, darkness was over the surface of the deep, and the Spirit of God was hovering over the waters.
And God said, “Let there be light,” and there was light. 
God saw that the light was good, 
and he separated the light from the darkness.
God called the light “day,” and the darkness he called “night.” 
And there was evening, and there was morning—the first day.

Genesis 1-1 German in Germany
-----------------------------

Im Anfang schuf Gott Himmel und Erde.
Und die Erde war wüst und leer, und es war ﬁnster auf der Tiefe;
und der Geist Gottes schwebte auf dem Wasser.
Und Gott sprach: Es werde Licht! Und es ward Licht.
Und Gott sah, dass das Licht gut war.
Da schied Gott das Licht von der Finsternis
und nannte das Licht Tag und die Finsternis Nacht.
Da ward aus Abend und Morgen der erste Tag.

Genesis 1-1 Spanish in Argentina
--------------------------------

En el principio creó Dios los cielos y la tierra. 
Y la tierra estaba desordenada y vacía, y las tinieblas estaban sobre la faz del abismo,
Y el Espíritu de Dios se movía sobre la faz de las aguas. 
Y dijo Dios: Sea la luz! Y fue la luz. 
Y vio Dios que la luz era buena; 
Y separó Dios la luz de las tinieblas. 
Y llamó Dios a la luz Día, y a las tinieblas llamó Noche. 
Y fue la tarde y la mañana un día.

