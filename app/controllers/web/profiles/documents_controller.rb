class Web::Profiles::DocumentsController < Web::ProfilesController
  include Pundit
  include Web::DocumentsHelper

  before_action :load_user
  before_action :load_document
  # after_action :verify_authorized

  def show
    authorize @document
    render "web/documents/show"
  end

  protected

  def load_user
    @user = User.find_by_username!(user_id)
  end

  def load_document
    @document = @user.documents.friendly.find(params[:id])
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
end
