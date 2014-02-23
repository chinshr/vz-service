class Message::Inbound < Message
  validates :from, presence: true
  validates_associated :attachments
end