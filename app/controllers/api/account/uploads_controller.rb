class Api::Account::UploadsController < Api::ApplicationController
  
  # [POST] /api/account/uploads.json
  def create
    @upload = Upload.new(create_params.permit(:type)) do |u|
      u.session_id = current_session.id if current_session
    end
    @upload.attributes = create_params.except(:type)
    @upload.save
    respond_with "api", @upload
  end

  # [GET] /api/account/uploads.json
  def index
    @uploads = current_session.uploads.any_of_states(:foobar) if current_session
    respond_with @uploads
  end

  # [GET] /api/account/uploads/1.json
  def show
    @upload = Upload.find(params[:id])
    respond_with @upload
  end

  # [PUT] /api/account/uploads/1.json
  def update
    @upload = Upload.update(params[:id], update_params)
    respond_with @upload
  end

  # [DELETE] /api/account/uploads/1.json
  def destroy
    respond_with Upload.destroy(params[:id])
  end
  
  protected

  def create_params
    params.require(:upload).permit(:type, :file_name, :file_type, :file_size, :s3_url, :locale, :privacy)
  end

  def update_params
    params.require(:upload).permit(:title, :description, :locale, :privacy)
  end
end
