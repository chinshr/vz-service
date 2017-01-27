class Web::Devise::RegistrationsController < Devise::RegistrationsController
  include Payola::StatusBehavior
  include PaymentBehavior

  respond_to :html, :js

  before_action :find_plan, only: [:new, :create]
  before_action :cancel_subscription, only: [:destroy]
  before_action :check_captcha, only: [:create], if: :requires_captcha?

  def new
    build_resource({})
    resource.plan = @plan if @plan.present?
    yield resource if block_given?
    respond_with self.resource
  end

  def create
    build_resource(sign_up_params) unless resource

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        if @plan.present?
          create_subscription(resource)
        else
          respond_with resource, location: after_sign_up_path_for(resource)
        end
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        if @plan.present?
          create_subscription(resource)
        else
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      end
    else
      clean_up_passwords resource
      if @plan.present?
        render json: {error: resource.errors.full_messages.to_sentence},
          status: 400
      else
        respond_with resource
      end
    end
  end

  protected

  def sign_up_params
    params.require(:user).permit(:email, :time_zone, :plan_id)
  end

  private

  def requires_captcha?
    !@plan
  end
  helper_method :requires_captcha?

  def check_captcha
    build_resource(sign_up_params) unless self.resource.present?
    unless verify_recaptcha(model: resource, attribute: :captcha)
      respond_with_navigational(resource) { render :new }
    end
  end
end
