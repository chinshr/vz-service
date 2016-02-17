class Api::Account::ApplicationController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
end
