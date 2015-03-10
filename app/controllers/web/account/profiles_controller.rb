class Web::Account::ProfilesController < Web::Account::ApplicationController

  def update
    @user = current_user
    flash[:notice] = "Sucessfully updated."
    if @user = User.update(@user.id, account_profile_params)
      respond_with @user, :location => web_account_profile_path
    else
      respond_with @user
    end
  end

protected

  def account_profile_params
    params.require(:user).permit(:first_name, :last_name, :time_zone, :css_hex_color, :initials)
  end

end
