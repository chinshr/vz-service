module Api
  module Authorization
    class << self
      def included(base, *params)
        base.send :include, InstanceMethods
        base.send :extend, ClassMethods

        base.send :alias_method_chain, :authenticate_user!, :authorization
      end
    end

    module InstanceMethods
      protected

      # overrides devise authenticate_user!
      def authenticate_user_with_authorization!
        authorize_client!
        authorize_user!
      rescue Api::Exception::AuthorizationError => ex
        authenticate_user_without_authorization!
      end

      def authorize_client_or_signed_in_user!
        authorize_client!
      rescue Api::Exception::AuthorizationError => ex
        raise ex unless user_signed_in?
      end

      # ?access_token=<access-token>
      # or header 'Authorization'
      def access_token
        params[:access_token] || request.headers['HTTP_AUTHORIZATION']
      end

      def authorize_client!
        @client_access = Api::ClientAccess.active.includes(:user, {:client => :platform}).find_by(uid: access_token) if access_token

        if !@client_access
          raise Api::Exception::AuthorizationError.new(I18n.t('api.error_code.authorization_error.access_token'))
        elsif @client_access.platform && !@client_access.platform.active?
          raise Api::Exception::AuthorizationError.new(I18n.t('api.error_code.authorization_error.platform'))
        end
      end

      def authorize_user!
        if current_access.try(:user_id)
          sign_in current_access.user, store: false
        else
          raise Api::Exception::AuthorizationError.new(I18n.t('api.error_code.authorization_error.user'))
        end
      end

      def current_access
        @client_access
      end

      def current_client
        @current_client ||= @client_access.client
      end
    end

    module ClassMethods
      def skip_authorize_client!(*actions)
        skip_before_action :authorize_client!, (actions.blank? ? nil : {:only => actions})
      end

      def skip_authorize_user!(*actions)
        skip_before_action :authorize_user!, (actions.blank? ? nil : {:only => actions})
      end
    end
  end
end