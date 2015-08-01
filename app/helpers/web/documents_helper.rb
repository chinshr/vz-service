module Web::DocumentsHelper
  extend ActiveSupport::Concern

  included do
    helper Helper if respond_to?(:helper)

    if respond_to?(:helper_method)
      helper_method :dom_controller_action_class
      helper_method :waveform_visible?
    end

    if respond_to?(:hide_action)
      hide_action :dom_controller_action_class
      hide_action :waveform_visible?
    end
  end

  module Helper

    def published_document_url(user_slug = nil, document_slug = nil)
      user_slug     ||= current_user.slug if defined?(current_user) && current_user
      document_slug ||= @document.slug if @document
      web_profile_document_url("@#{user_slug}", document_slug) if user_slug && document_slug
    end

    def edit?
      controller.is_a?(Web::DocumentsController) && action_name == "edit"
    end

    def show?
      controller.is_a?(Web::DocumentsController) && action_name == "show"
    end

    def publish?
      controller.is_a?(Web::Profiles::DocumentsController) && action_name == "show"
    end

    def publish_icon_class
      return "fa-cloud"
      if @document.privacy_private?
        "fa-lock"
      elsif @document.privacy_unlisted?
        "fa-eye-slash"
      else
        "fa-cloud" # "fa-unlock" # "fa-unlock-alt" # "fa-book"
      end
    end

    def document_title
      if publish?
        "#{@document.title} — VOYZ.ES"
      elsif show?
        "Viewing #{@document.title}"
      elsif edit?
        "Editing #{@document.title}"
      end
    end
  end

  def waveform_visible?
    params[:wf] && !Model::Helper.booleanize(params[:wf]) ? false : true
  end

  def dom_controller_action_class
    "#{action_name.dasherize} waveform-#{waveform_visible? ? 'visible' : 'hidden'}"
  end
end