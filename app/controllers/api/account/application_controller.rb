class Api::Account::ApplicationController < Api::ApplicationController
  before_filter :authenticate_user!
  
end
