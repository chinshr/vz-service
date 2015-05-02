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
    @chunk = @ingest.ingest_chunks.create(create_params)
    @chunk.reload unless @chunk.new_record?
    respond_with @chunk
  end

  # [GET] /api/ingests/:ingest_id/chunks(.:format)
  def index
    authorize :"ingest/chunk"
    @chunks = @ingest.ingest_chunks.filter(params)
    respond_with @chunks
  end

  # [GET] /api/ingests/:ingest_id/count(.:format)
  def count
    authorize :"ingest/chunk"
    render :json => {:count => @ingest.ingest_chunks.filter(params).count}
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
    @ingest.ingest_chunks.destroy(@chunk)
    respond_with @chunk
  end

  protected

  def load_ingest
    @ingest = Ingest.find(params[:ingest_id])
  end

  def load_chunk
    @chunk = @ingest.ingest_chunks.find(params[:id])
  end

  def create_params
    params.require(:chunk).permit(*policy(:"ingest/chunk").permitted_attributes).tap do |whitelisted|
      whitelisted[:response]          = params[:chunk][:response] if params[:chunk][:response]
      whitelisted[:processing_errors] = params[:chunk][:processing_errors] if params[:chunk][:processing_errors]
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