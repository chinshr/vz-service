class Api::IngestsController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :load_ingest, :only => [:show, :update, :destroy]
  after_action :verify_authorized

  # [GET] /api/ingests(.:format)
  def index
    authorize :ingest
    @ingests = Ingest.filter(params)
    respond_with @ingests
  end

  # [GET] /api/ingests/count(.:format)
  def count
    authorize :ingest
    render :json => {:count => Ingest.filter(params).count}
  end

  # [GET] /api/ingests/:id(.:format)
  def show
    authorize @ingest
    respond_with @ingest
  end

  # [PUT] /api/ingests/:id(.:format)
  def update
    authorize @ingest
    @ingest.update_attributes(update_params)
    respond_with @ingest
  end

  # [DELETE] /api/ingests/:id(.:format)
  def destroy
    authorize @ingest
    @ingest.destroy
    respond_with @ingest
  end

  protected

  def load_ingest
    @ingest = Ingest.eager_load(:upload, :document => :track).find(params[:id])
  end

  def update_params
    params.require(:ingest).permit(*policy(@ingest).permitted_attributes(action_name)).tap do |whitelisted|
      whitelisted[:messages] = params[:ingest][:messages] if params[:ingest][:messages]
    end

  end
end
