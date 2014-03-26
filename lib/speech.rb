# -*- encoding: binary -*-

require 'curb'
require 'json'
require 'uuid'

module Speech; end

require 'speech/audio_inspector'
require 'speech/audio_splitter'
require 'speech/audio_to_text'
require 'speech/engines/base'
require 'speech/engines/att_speech_engine'
require 'speech/engines/google_speech_engine'
