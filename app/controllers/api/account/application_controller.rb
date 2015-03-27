class Api::Account::ApplicationController < Api::ApplicationController
  before_action :authenticate_user!
end
