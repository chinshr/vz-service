class Web::Devise::ConfirmationsController < ::Devise::ConfirmationsController
  respond_to :html, :js

  # Remove the first skip_before_filter (:require_no_authentication) if you
  # don't want to enable logged users to access the confirmation page.
  skip_before_filter :require_no_authentication
  skip_before_filter :authenticate_user!

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    with_unconfirmed_confirmable do
      if @confirmable.has_no_password?
        do_show
      else
        do_confirm
      end
    end
    if !@confirmable.errors.empty?
      self.resource = @confirmable
      render 'new' #Change this if you don't have the views on default path
    end
  end

  # PUT /resource/confirmation
  def update
    with_unconfirmed_confirmable do
      if @confirmable.has_no_password?
        @confirmable.confirm_set_with user_params

        if @confirmable.valid?
          do_confirm
        else
          do_show
          @confirmable.errors.clear # so that we wont render :new
        end
      else
        self.class.add_error_on(self, :email, :password_allready_set)
      end
    end

    if !@confirmable.errors.empty?
      render 'new' #Change this if you don't have the views on default path
    end
  end

  protected

  def with_unconfirmed_confirmable
    original_token = params[:confirmation_token]
    confirmation_token = Devise.token_generator.digest(User, :confirmation_token, original_token)
    @confirmable = User.find_or_initialize_with_error_by(:confirmation_token, confirmation_token)
    @confirmable.confirmation_validation = true if @confirmable
    if !@confirmable.new_record?
      @confirmable.only_if_unconfirmed { yield }
    end
  end

  def do_show
    @confirmation_token = params[:confirmation_token]
    @requires_password = true
    self.resource = @confirmable
    render 'show' # Change this if you don't have the views on default path
  end

  def do_confirm
    @confirmable.confirm!
    set_flash_message :notice, :confirmed

    respond_to do |format|
      format.html { sign_in_and_redirect(resource_name, @confirmable) }
      format.js { sign_in(resource_name, @confirmable) }
    end
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :first_name, :last_name, :username)
  end
end