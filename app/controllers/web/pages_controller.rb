class Web::PagesController < Web::ApplicationController
  before_action :set_cache_headers

  def index
    render :layout => "beachstrap"
  end

  def pricing
    @plans = Plan.with_stripe.visible.order(display_order: :asc)
    @subscription = Payola::Subscription.find_by(owner_id: current_user.id) if current_user
  end

  def faq
  end

  protected

  def set_cache_headers
    if Rails.env.production?
      last_modified = File.mtime("#{Rails.root}/app/views/web/pages/#{action_name}.html.erb")
      fresh_when last_modified: last_modified , public: true, etag: last_modified
      expires_in rack_cache_time, public: true
    end
  end
end
