class Api::DocumentsController < Api::ApplicationController
  include Pundit

  before_action :load_document, :only => [:show, :edit, :update, :destroy]

  # [GET] /api/documents(.:format)
  def index
    @documents = Document.with_user_privacy(current_user).filter(params)
    respond_with @documents
  end

  # [GET] /api/documents/count(.:format)
  def count
    render :json => {:count => Document.with_user_privacy(current_user).filter(params).count}
  end

  # [GET] /api/documents/:id(.:format)
  def show
    authorize @document
    respond_with @document
  end

  # [PUT] /api/documents/:id(.:format)
  def update
    authorize @document
    @document.update_attributes(update_params)
    respond_with @document
  end

  # [DELETE] /api/documents/:id(.:format)
  def destroy
    authorize @document
    @document.destroy
    respond_with @document
  end

  protected

  def update_params
    params.require(:document).permit(*policy(@document).permitted_attributes).tap do |whitelisted|
      whitelisted[:rich_text] = params[:document][:rich_text] if params[:document][:rich_text]
    end
  end
end
