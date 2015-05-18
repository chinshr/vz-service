class Web::MechanicalTurk::Documents::ChunksController < Web::MechanicalTurk::ApplicationController
  before_action :load_document
  after_action :allow_iframe

  def new
    @disabled = Turkee::TurkeeFormHelper::disable_form_fields?(params)
    @chunk    = Chunk::MechanicalTurk.new(document: @document, position: @document.position)
  end

  protected

  def load_document
    # load only 'chunk documents'
    @document = Document.where(uid: params[:document_id]).is_root(false).first!
  end

  def allow_iframe
    response.headers.delete "X-Frame-Options"
  end
end
