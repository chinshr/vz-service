class Web::ProfilesController < Web::ApplicationController
  before_action :load_user, only: :show

  def show
  end

  protected

  def load_user
    @user = User.friendly.find(user_id)
    # found, but since historic slug, redirect to canonical URL
    redirect_permanently_to_canonical_url if @user.slug != user_id
    true
  end

  def user_id
    un = params[:id]
    un.gsub!("@", "") if un
    un
  end

  def redirect_permanently_to_canonical_url
    redirect_to web_profile_url("@#{user_id}"), status: :moved_permanently
    return
  end

end
