class Api::TracksController < Api::ApplicationController
  before_filter :load_document

  def show
    @document.track
  end
  
  protected
  
  def load_document
    @document = Document.find(params[:document_id])
  end
end
