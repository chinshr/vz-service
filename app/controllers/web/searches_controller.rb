class Web::SearchesController < Web::ApplicationController

  def index
    find_users
  end

  protected

  def find_users
    @users = User.confirmed.any_of_roles(:user).limit(5)
      .where("users.username LIKE ? OR users.first_name LIKE ? OR users.last_name LIKE ? OR users.description LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
  end

  def search_all?
    class_name == "web/searches_controller"
  end
  helper_method :search_all?

  def search_users?
    class_name == "web/searches/users_controller"
  end
  helper_method :search_users?

  private

  # E.g. "web_searches_controller" or "web_searches_users_controller"
  def class_name
    self.class.name.underscore
  end

end
