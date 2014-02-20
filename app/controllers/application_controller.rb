class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :session_required
  
  protected
  
  def session_required
    if session && session[:session_id].present? && !current_session
      self.current_session = Session.where(uid: session[:session_id]).first_or_create! do |session|
        session.ip         = request.ip
        session.user_agent = request.user_agent
      end
    end
  end

  def current_session
    @current_session ||= (session_from_session || session_from_cookie) unless @current_session == false
  end
  helper_method :current_session

  def current_session=(new_session)
    session[session_param] = new_session ? new_session.uid : nil
    cookies[cookie_auth_token] = {:value => new_session ? new_session.uid : nil, :expires => Time.now + 1.year}
    @current_session = new_session || false
  end

  def session_from_session
    self.current_session = Session.find_by_uid(session[session_param]) if session[session_param]
  end

  def session_from_cookie
    session = cookies[cookie_auth_token] && Session.find_by_uid(cookies[cookie_auth_token])
    if session
      cookies[cookie_auth_token] = {
        :value => session.uid,
        :expires => Time.now + 1.year
        # :domain => "domain.com"
      }
      self.current_session = session
    end
  end
  
  def session_param
    :session_record_id
  end
  
  def cookie_auth_token
    "#{session_param}_auth_token".to_sym
  end
end
