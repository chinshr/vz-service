class Api::TracksController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :load_document
  before_action :load_track, only: [:show, :update, :destroy]
  after_action :verify_authorized

  # [POST] /api/documents/:document_id/tracks(.:format)
  def create
    authorize :track
    @track = @document.create_track(create_params)
    respond_with "api", @document, @track
  end

  # [PUT] /api/documents/:document_id/tracks/:id(.:format)
  def update
    authorize @track
    @track = Track.update(params[:id], update_params)
    respond_with @track
  end

  # [GET] /api/documents/:document_id/tracks(.:format)
  def index
    authorize :track
    @tracks = @document.tracks_including_master_track.filter(params)
    respond_with @tracks
  end

  # [GET] /api/documents/:document_id/tracks/:id(.:format)
  def show
    authorize @track
    respond_with @track
  end

  # [DELETE] /api/documents/:document_id/tracks/:id(.:format)
  def destroy
    authorize @track
    @document.tracks_including_master_track.destroy(@track)
    respond_with @track
  end

  protected

  def load_document
    @document = Document.find(params[:document_id])
  end

  def load_track
    @track = @document.tracks_including_master_track.find(params[:id])
  end

  def create_params
    params.require(:track).permit(policy(:track).permitted_attributes)
  end
  alias_method :update_params, :create_params
end