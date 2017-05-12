class Plan < ApplicationRecord
  include Model::Uid
  include Payola::Plan

  serialize :config, Plan::Config

  has_many :users

  validates :stripe_id, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }
  scope :visible, -> { where(visible: true) }
  scope :hidden, -> { where(visible: false) }
  scope :with_stripe, -> { where(create_stripe: true) }
  scope :without_stripe, -> { where(create_stripe: false) }

  class << self
    def generate_uid
      SecureRandom.uuid
    end
  end

  def redirect_path(subscription)
    if subscription.owner && subscription.owner.confirmed?
      Rails.application.routes.url_helpers.web_account_billing_path
    else
      Rails.application.routes.url_helpers.new_user_session_path
    end
  end

  protected

  # Note: callback only if `Payola.create_stripe_plans = true`
  def create_stripe_plan
    Payola::CreatePlan.call(self) if create_stripe?
  end
end
