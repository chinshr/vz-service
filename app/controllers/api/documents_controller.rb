class Api::DocumentsController < Api::ApplicationController
  include Pundit
  before_action :load_document, :only => [:show, :edit, :update, :destroy]
  before_action :authenticate_user_with_action!
  
  # [GET] /api/documents(.:format)
  def index
    @documents = Documents.filter(params)
    respond_with @documents
  end

  # [GET] /api/documents/count(.:format)
  def count
    render :json => {:count => Document.filter(params).count}
  end

  # [GET] /api/documents/:id(.:format)
  def show
    authorize @document
    respond_with @document
  end

  # [PUT] /api/documents/:id(.:format)
  def update
    authorize @document
    @document.attributes = update_params
    @document.save
    respond_with @document
  end

  # [DELETE] /api/documents/:id(.:format)
  def destroy
    authorize @document
    @document.destroy
    respond_with @upload
  end

  protected

  def update_params
    params.require(:document).permit(:title, :description, {:tag_list => []}, :locale, :privacy)
  end

  def load_document
    @document = Document.where("documents.slug = ? OR documents.id = ?", params[:id], params[:id].to_i).first!
  end
  
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
