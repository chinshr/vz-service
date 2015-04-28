class Api::Ingests::ChunksController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :load_ingest
  before_action :load_chunk, only: [:show, :update, :destroy]
  after_action :verify_authorized

  # [POST] /api/ingests/:ingest_id/chunks(.:format)
  def create
    authorize :chunk
    @chunk = @ingest.ingest_chunks.create(create_params)
    respond_with @chunk
  end

  # [GET] /api/ingests/:ingest_id/chunks(.:format)
  def index
    authorize :chunk
    @chunks = @ingest.ingest_chunks.filter(params)
    respond_with @chunks
  end

  # [GET] /api/ingests/:ingest_id/count(.:format)
  def count
    authorize :chunk
    render :json => {:count => @ingest.ingest_chunks.filter(params).count}
  end

  # [GET] /api/ingests/:ingest_id/chunks/:id(.:format)
  def show
    authorize @chunk
    respond_with @chunk
  end

  # [PUT] /api/ingests/:ingest_id/chunks/:id(.:format)
  def update
    authorize @chunk
    @chunk = Chunk.update(params[:id], update_params)
    respond_with @chunk
  end

  # [DELETE] /api/ingests/:ingest_id/chunks/:id(.:format)
  def destroy
    authorize @chunk
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
    params.require(:chunk).permit(*whitelisted_keys).tap do |whitelisted|
      whitelisted[:response] = params[:chunk][:response] if params[:chunk][:response]
      whitelisted[:processing_errors] = params[:chunk][:processing_errors] if params[:chunk][:processing_errors]
    end
  end
  alias_method :update_params, :create_params

  def whitelisted_keys
    [:type, :position, :offset, :duration, :start_time, :end_time,:text, :score, 
      :response, :processing_errors, :processing_status]
  end

end