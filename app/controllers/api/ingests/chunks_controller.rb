class Api::Ingests::ChunksController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :load_ingest
  before_action :load_chunk, only: [:show, :update, :destroy]
  after_action :verify_authorized

  # [POST] /api/ingests/:ingest_id/chunks(.:format)
  def create
    authorize :"ingest/chunk"
    @chunk = @ingest.chunks.create(create_params)
    @chunk.reload unless @chunk.new_record?
    respond_with @chunk
  end

  # [GET] /api/ingests/:ingest_id/chunks(.:format)
  # [GET] /api/ingests/chunks(.:format)
  def index
    authorize :"ingest/chunk"
    @chunks = Chunk.filter(params)
    respond_with @chunks
  end

  # [GET] /api/ingests/:ingest_id/count(.:format)
  def count
    authorize :"ingest/chunk"
    render :json => {:count => @ingest.chunks.filter(count_params).count}
  end

  # [GET] /api/ingests/:ingest_id/chunks/:id(.:format)
  def show
    authorize :"ingest/chunk"
    respond_with @chunk
  end

  # [PUT] /api/ingests/:ingest_id/chunks/:id(.:format)
  def update
    authorize :"ingest/chunk"
    @chunk = Chunk.update(params[:id], update_params)
    @chunk.reload
    respond_with @chunk
  end

  # [DELETE] /api/ingests/:ingest_id/chunks/:id(.:format)
  def destroy
    authorize :"ingest/chunk"
    @ingest.chunks.destroy(@chunk)
    respond_with @chunk
  end

  protected

  def load_ingest
    @ingest = Ingest.find(params[:ingest_id]) if params[:ingest_id]
  end

  def load_chunk
    @chunk = @ingest.chunks.find(params[:id])
  end

  def create_params
    params.require(:chunk).permit(*policy(:"ingest/chunk").permitted_attributes(action_name)).tap do |whitelisted|
      whitelisted[:response]          = params[:chunk][:response] if params[:chunk][:response]
      whitelisted[:words]             = params[:chunk][:words] if params[:chunk][:words]
      whitelisted[:processing_errors] = params[:chunk][:processing_errors] if params[:chunk][:processing_errors]
      whitelisted[:ingest]            = @ingest
      whitelisted[:ingest_iteration]  = params[:chunk][:ingest_iteration] || @ingest.iteration
    end
  end

  def update_params
    up = create_params
    if up[:track_attributes] && @chunk && @chunk.track
      up[:track_attributes].merge!(id: @chunk.track.id)
    end
    up
  end
end