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
    @document.track.try(:destroy)
    @track = Track.create(create_params.merge(document: @document, ingest: @ingest))
    respond_with "api", @document, @track
  end

  # [PUT] /api/ingests/:ingest_id/tracks/:id(.:format)
  def update
    authorize :"ingest/track"
    @track = Track.update(params[:id], update_params)
    respond_with @track
  end

  protected

  def load_ingest_and_document
    @ingest = Ingest.find(params[:ingest_id])
    @document = @ingest.document
  end

  def create_params
    params.require(:track).permit(policy(:"ingest/track").permitted_attributes)
  end

  def update_params
    params.require(:track).permit(policy(:"ingest/track").permitted_attributes)
  end
end