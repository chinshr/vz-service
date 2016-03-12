class Web::Account::SettingsController < Web::Account::ApplicationController

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    @user = current_user
    prev_unconfirmed_email = @user.unconfirmed_email if @user.respond_to?(:unconfirmed_email)

    if update_resource(@user, account_update_params)
      flash_key = update_needs_confirmation?(@user, prev_unconfirmed_email) ?
        :update_needs_confirmation : :updated
      set_flash_message :success, flash_key
      sign_in resource_name, @user, :bypass => true
      respond_with @user, :location => after_update_path_for(@user)
    else
      set_flash_message :error, :not_updated
      @user.reload  # make sure invalid data is not rendered
      clean_up_passwords @user
      respond_with @user
    end
  end

  protected

  def update_needs_confirmation?(resource, previous)
    resource.respond_to?(:pending_reconfirmation?) &&
      resource.pending_reconfirmation? &&
      previous != resource.unconfirmed_email
  end

  # By default we want to require a password checks on update.
  # You can overwrite this method in your own RegistrationsController.
  def update_resource(resource, params)
    resource.update_with_password(params)
  end

  def account_update_params
    params.require(:user).permit(:current_password, :email, :password, :password_confirmation, :username)
  end

  def clean_up_passwords(object)
    object.clean_up_passwords if object.respond_to?(:clean_up_passwords)
  end

  def after_update_path_for(resource)
    # signed_in_root_path(resource)
    web_account_settings_path
  end
end