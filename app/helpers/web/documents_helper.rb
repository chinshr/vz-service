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

    # override from app helper
    def page_title(caption = nil, with_brand_name = false)
      caption ||= if publish?
        "#{@document.title} — VOYZ.ES"
      elsif show?
        "Viewing #{@document.title}"
      elsif edit?
        "Editing #{@document.title}"
      end
      caption += " — VOYZ.ES" if with_brand_name
      content_for(:title, caption)
    end

    def published_document_url(user_slug = nil, document_slug = nil)
      user_slug     ||= current_user.slug if defined?(current_user) && current_user
      document_slug ||= if @document && !@document.privacy_private? && @document.published?
        @document.slug
      end
      web_profile_document_url("@#{user_slug}", document_slug) if user_slug && document_slug
    end

    def show_document_url
      if @document && @document.privacy_private?
        web_document_url(@document.slug_id)
      elsif @document && !@document.privacy_private? && @document.published?
        published_document_url
      end
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

    def meta_privacy_description
      return unless @document
      if @document.privacy_public?
        "The document is publicly visible. It will be listed on VOYZ.ES public pages (e.g. homepage) and it can be found using a search engine."
      elsif @document.privacy_unlisted?
        "The document is only visible to those with the link. It won't be listed on VOYZ.ES public pages (e.g. homepage) and it cannot be found using a search engine."
      elsif @document.privacy_private?
        "The document will be private and not be published. Only you can edit and view the document."
      end
    end

    def meta_privacy_title
      return unless @document
      if @document.privacy_public?
        "Public"
      elsif @document.privacy_unlisted?
        "Limited"
      elsif @document.privacy_private?
        "Private"
      end
    end

    def meta_privacy_icon
      return unless @document
      if @document.privacy_public?
        "fa fa-unlock"
      elsif @document.privacy_unlisted?
        "fa fa-eye-slash"
      elsif @document.privacy_private?
        "fa fa-lock"
      end
    end

    def humanize_date(date_or_time)
      if date_or_time.year == Time.zone.now.year
        date_or_time.strftime("%b %-d")
      else
        date_or_time.strftime("%b %-d, %Y")
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