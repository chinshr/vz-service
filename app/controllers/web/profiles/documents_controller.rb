class Web::Profiles::DocumentsController < Web::ProfilesController
  include Pundit
  include Web::DocumentsHelper

  before_action :load_user
  before_action :load_document
  after_action :verify_authorized, only: [:show]

  def show
    authorize @document
    respond_to do |format|
      format.html
      format.srt
      format.txt
      format.mp3 {
        redirect_to @document.track.mp3_stream_url
      }
    end
  end

  protected

  def load_user
    @user = User.friendly.find(user_id)
    # found, but since historic slug, redirect to canonical URL
    redirect_permanently_to_canonical_url if @user.slug != user_id
    true
  end

  def load_document
    @document = @user.documents.friendly.find(params[:id])
    # found, but since historic slug, redirect to canonical URL
    redirect_permanently_to_canonical_url if @document.slug != params[:id]
  end

  def user_id
    un = params[:user_id]
    un.gsub!("@", "") if un
    un
  end

  # override to support nested policy 'profile/document'
  def authorize(record, query = nil)
    query ||= params[:action].to_s + "?"

    @_pundit_policy_authorized = true

    policy = policy(:"profile/document")
    policy.record = record

    unless policy.public_send(query)
      raise NotAuthorizedError.new(query: query, record: record, policy: policy)
    end

    true
  end

  def redirect_permanently_to_canonical_url
    redirect_to web_profile_document_url("@#{user_id}", @document.slug), status: :moved_permanently
    return
  end

  def verify_authorized
    raise AuthorizationNotPerformedError unless pundit_policy_authorized?
  end

  def pundit_policy_authorized?
    !!@_pundit_policy_authorized
  end
end
