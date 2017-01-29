class Web::Devise::ConfirmationsController < ::Devise::ConfirmationsController
  respond_to :html, :js

  # Remove the first skip_before_filter (:require_no_authentication) if you
  # don't want to enable logged users to access the confirmation page.
  skip_before_action :require_no_authentication
  skip_before_action :authenticate_user!

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
      render 'new' # Change this if you don't have the views on default path
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
      render 'new' # change this if you don't have the views on default path
    end
  end

  protected

  def with_unconfirmed_confirmable
    confirmation_token = params[:confirmation_token]
    @confirmable = User.find_or_initialize_with_error_by(:confirmation_token, confirmation_token)
    @confirmable.confirmation_validation = true if @confirmable
    if !@confirmable.new_record?
      @confirmable.only_if_unconfirmed { yield }
    end
  end

  def do_show
    @confirmation_token = params[:confirmation_token]
    @requires_password  = true
    self.resource       = @confirmable
    render 'show' # Change this if you don't have the views on default path
  end

  def do_confirm
    @confirmable.confirm
    set_flash_message :notice, :confirmed
    self.resource = @confirmable

    respond_to do |format|
      format.html { sign_in_after_confirmation_and_redirect(resource_name, @confirmable) }
      format.js { sign_in_after_confirmation(resource_name, @confirmable) }
    end
  end

  def user_params
    params.require(:user).permit(:password, :name, :username)
  end

  private

  # sign_in_and_redirect from devise/controllers/helpers.rb
  def sign_in_after_confirmation_and_redirect(resource_or_scope, *args)
    options   = args.extract_options!
    scope    = Devise::Mapping.find_scope!(resource_or_scope)
    resource = args.last || resource_or_scope

    if resource.active_for_authentication?
      # sign in an go to dashboard
      sign_in(scope, resource, options)
      redirect_to after_sign_in_path_for(resource)
    else
      # make the user sign in for the first time
      redirect_to after_confirmation_path_for(scope, resource)
    end
  end

  def sign_in_after_confirmation(resource_or_scope, *args)
    options  = args.extract_options!
    scope    = Devise::Mapping.find_scope!(resource_or_scope)
    resource = args.last || resource_or_scope

    if resource.active_for_authentication?
      sign_in(scope, resource, options)
    end
  end

  helper_method :after_sign_in_path_for # used for update.js.erb
  helper_method :after_confirmation_path_for # used for update.js.erb
end