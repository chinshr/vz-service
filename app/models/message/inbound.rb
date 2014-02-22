class Message::Inbound < Message
  validates :from, presence: true
end