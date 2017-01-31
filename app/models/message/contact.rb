class Message::Contact < Message
  validates :from, presence: true, email_format: true
  validates :sender_name, presence: true
  validates :body, presence: true

  after_commit :deliver_mail, on: :create

  def deliver_mail
    Message::ContactMailer.confirmation(self).deliver_later
  end
end
