class Api::Ingests::WorkersController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :load_ingest, only: [:create]
  before_action :load_worker, only: [:show, :update, :destroy]
  after_action :verify_authorized

  # [POST] /api/ingests/:ingest_id/workers(.:format)
  def create
    authorize :"ingest/worker"
    @worker = Ingest::Worker.create(create_params)
    respond_with @worker, location: resource_url do |format|
      format.json { render 'create', status: http_status(@worker) }
      format.xml  { render 'create', status: http_status(@worker) }
    end
  end

  # [PUT] /api/ingests/:ingest_id/workers/:id(.:format)
  def update
    authorize :"ingest/worker"
    @worker.update_attributes(update_params)
    respond_with @worker do |format|
      format.json { render 'update', status: http_status(@worker) }
      format.xml  { render 'update', status: http_status(@worker) }
    end
  end

  # [GET] /api/ingests/:ingest_id/workers(.:format)
  def index
    authorize :"ingest/worker"
    @workers = Ingest::Worker.filter(params)
    respond_with @workers
  end

  # [GET] /api/ingests/:ingest_id/workers/count(.:format)
  def count
    authorize :"ingest/worker"
    render :json => {:count => Ingest::Worker.filter(count_params).count}
  end

  # [GET] /api/ingests/:ingest_id/workers/:id(.:format)
  def show
    authorize :"ingest/worker"
    respond_with @worker
  end

  # [DELETE] /api/ingests/:ingest_id/workers/:id(.:format)
  def destroy
    authorize :"ingest/worker"
    @worker.destroy
    respond_with @worker
  end

  protected

  def load_ingest
    @ingest = Ingest.find(params[:ingest_id])
  end

  def load_worker
    @worker = ::Ingest::Worker.eager_load_associations.filter(params).find(params[:id])
  end

  def create_params
    params.require(:worker).permit(policy(:"ingest/worker").permitted_attributes(action_name)).merge(ingest: @ingest).tap do |whitelisted|
      whitelisted[:messages] = params[:worker][:messages].as_json if params[:worker][:messages]
    end
  end

  def update_params
    params.require(:worker).permit(policy(:"ingest/worker").permitted_attributes(action_name)).tap do |whitelisted|
      whitelisted[:messages] = params[:worker][:messages].as_json if params[:worker][:messages]
    end
  end

  def http_status(record)
    # http://apidock.com/rails/ActionController/Base/render#254-List-of-status-codes-and-their-symbols
    if action_name == "create"
      record.valid? ? :created : :unprocessable_entity
    elsif action_name == "update"
      record.valid? ? :ok : :unprocessable_entity
    end
  end

  def resource_url
    if @worker.valid?
      api_ingest_worker_url(@ingest, @worker)
    end
  end
end
