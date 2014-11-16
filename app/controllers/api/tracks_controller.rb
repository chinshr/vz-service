class Api::TracksController < Api::ApplicationController
  before_action :load_document

  # [GET] /api/documents/:document_id/tracks(.:format)
  def index
    @tracks = @document.tracks.filter(params)
    respond_with @tracks
  end

  # [GET] /api/documents/:document_id/tracks/:id(.:format)
  def show
    @track = @document.tracks.find(params[:id])
    respond_with @track
  end

  protected

  def load_document
    @document = Document.find(params[:document_id])
  end
end
