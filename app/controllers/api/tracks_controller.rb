class Api::TracksController < Api::ApplicationController
  include Pundit
  include Api::Authorization

  before_action :authenticate_user!
  before_action :load_document
  before_action :load_track
  after_action :verify_authorized

  # [GET] /api/documents/:document_id/tracks(.:format)
  def index
    authorize :track
    @tracks = @document.tracks.filter(params)
    respond_with @tracks
  end

  # [GET] /api/documents/:document_id/tracks/:id(.:format)
  def show
    authorize :track
    respond_with @track
  end

  protected

  def load_document
    @document = Document.find(params[:document_id])
  end

  def load_document
    @document = @document.tracks_including_master.find(params[:id])
  end

end