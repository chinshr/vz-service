class Web::MechanicalTurk::ApplicationController < Web::ApplicationController
  layout "mechanical_turk"

  after_filter :flash_to_headers

  protected

  def flash_to_headers
    return unless request.xhr?
    if tm = flash_type_and_message
      response.headers["X-Message-Type"] = tm.first
      response.headers['X-Message']      = tm.last
    end
    #flash.discard # don't want the flash to appear when you reload page
  end

  def flash_type_and_message
    flash.each do |key, message|
      return key, message
    end
    nil
  end
end
