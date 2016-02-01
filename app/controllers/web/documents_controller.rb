class Web::DocumentsController < Web::ApplicationController
  include Pundit
  include Web::DocumentsHelper

  before_action :load_document, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user_with_action!
  after_action :verify_authorized, only: [:show, :edit]

  def show
    authorize @document
    redirect_to_published_unless_previewable and return

    respond_to do |format|
      format.html
      format.srt
      format.txt
      format.mp3 {
        redirect_to @document.track.mp3_stream_url and return
      }
    end
  end

  def edit
    authorize @document
  end

  # TODO: still needed?
  def stream
    redirect_to @document.tracks.last.stream_url
  end

  protected

  def authenticate_user_with_action!
    case action_name
    when "show" then authenticate_user! if must_authenticate_with_show?
    when "edit" then authenticate_user! if must_authenticate_with_edit?
    end
  end

  def must_authenticate_with_show?
    @document.privacy_public? ? false : true
  end

  def must_authenticate_with_edit?
    true
  end

  def load_document
    @document = Document.where("documents.slug_id = ?", params[:id]).first!
  end

  def redirect_to_published_unless_previewable
    # The idea is that if a user shares the 'preview' link
    # with another user and the document is not editable, then
    # it does not make sense to show the preview, since the
    # document is not editable anyway, so redirect to
    # the published link.
    if (!current_user || (current_user && !current_user.owner_of?(@document))) && !@document.privacy_private? && !@document.accessibility_editable?
      redirect_to web_profile_document_path("@#{@document.user.username}", @document.slug), status: :moved_permanently
      return true
    end
    false
  end
end
