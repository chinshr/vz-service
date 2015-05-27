class Api::Ingests::TracksController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :load_ingest_and_document
  after_action :verify_authorized

  # Creates document's main track
  # [POST] /api/ingests/:ingest_id/tracks(.:format)
  def create
    authorize :"ingest/track"
    @track = Track.create(create_params)
    respond_with "api", @document, @track
  end

  # [PUT] /api/ingests/:ingest_id/tracks/:id(.:format)
  def update
    authorize :"ingest/track"
    @track = Track.update(params[:id], update_params)
    respond_with @track
  end

  # [GET] /api/ingests/:ingest_id/tracks(.:format)
  def index
    authorize :"ingest/track"
    @tracks = @ingest.tracks_including_master_track.filter(params)
    respond_with @tracks
  end

  # [GET] /api/ingests/:ingest_id/tracks/:id(.:format)
  def show
    authorize :"ingest/track"
    @track = @ingest.tracks_including_master_track.find(params[:id])
    respond_with @track
  end

  # [DELETE] /api/ingests/:ingest_id/tracks/:id(.:format)
  def destroy
    authorize :"ingest/track"
    @track = @ingest.tracks_including_master_track.find(params[:id])
    @track.destroy
    respond_with @track
  end

  protected

  def load_ingest_and_document
    @ingest = Ingest.find(params[:ingest_id])
    @document = @ingest.document
  end

  def create_params
    params.require(:track).permit(policy(:"ingest/track").permitted_attributes).merge(ingest: @ingest)
  end

  def update_params
    params.require(:track).permit(policy(:"ingest/track").permitted_attributes)
  end
end