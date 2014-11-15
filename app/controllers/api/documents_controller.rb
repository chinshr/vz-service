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
=begin
    authorize @document
    respond_with @document
=end
    render status: 404
  end

  # [PUT] /api/documents/:id(.:format)
  def update
    authorize @document
    @document = current_user.documents.update(params[:id], update_params)
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
    params.require(:document).permit(:title, :description, {:tag_list => []}, :locale, :privacy, :content)
  end
end
