class Web::DocumentsController < Web::ApplicationController
  include Pundit
  before_action :load_document, :only => [:show, :edit, :update, :destroy]
  before_action :authenticate_user_with_action!

  def show
    authorize @document
  end

  def edit
    authorize @document
  end

  def stream
    redirect_to @document.tracks.last.stream_url
  end

  protected

  def authenticate_user_with_action!
    case action_name
    when "show" then authenticate_user! if must_authenticate_with_show?
    when "edit" then authenticate_user! if must_authenticate_with_edit?
    end
  end

  def must_authenticate_with_show?
    @document.privacy_public? ? false : true
  end

  def must_authenticate_with_edit?
    true
  end
end
