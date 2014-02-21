class Message::Inbound < Message
  belongs_to :user
  
  validates :user, presence: true
end