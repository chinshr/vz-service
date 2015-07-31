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
  end

  def waveform_visible?
    params[:wf] && !Model::Helper.booleanize(params[:wf]) ? false : true
  end

  def dom_controller_action_class
    "#{action_name.dasherize} waveform-#{waveform_visible? ? 'visible' : 'hidden'}"
  end
end