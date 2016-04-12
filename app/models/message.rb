require 'nokogiri'
require 'whatlanguage'

class Message < ActiveRecord::Base
  self.table_name = "messages"
  include ::Model::Uid

  LANGUAGE_LOCALES = {
    arabic: "ar", english: "en", finnish: "fi", greek: "el", hebrew: "he",
    hungarian: "hu", norwegian: "no", polish: "pl", spanish: "es", dutch: "nl",
    portuguese: "pt", swedish: "sv", french: "fr", korean: "ko", russian: "ru",
    german: "de", italian: "it", farsi: "fa"
  }

  belongs_to :sender, foreign_key: :sender_id, class_name: "User"
  has_many :attachings, dependent: :destroy
  has_many :attachments, through: :attachings, source: :upload,
    class_name: "Upload::MediaUpload"

  class << self
    def generate_uid; SecureRandom.uuid; end
  end

  def text
    @text = self[:text] || begin
      Nokogiri::HTML(html).text
    end
  end

  # Determines locale via text that needs more than 3 words
  def locale
    content = [subject, text].join(" ").strip
    if content.split(" ").length > 3
      LANGUAGE_LOCALES[WhatLanguage.new(:all).language(content)]
    end
  end

  def valid_attachments?
    attachments.all? {|a| a.valid?}
  end
end
