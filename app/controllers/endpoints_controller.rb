# /endpoints/receive_email.xml
class EndpointsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :clean_fields
  
  def receive_email
    @user = User.find_or_create_by_email!(Helper::Mailer::unprettify(params["from"]))

    @message = Message::Inbound.new(message_params) do |m|
      m.user = @user
    end
    
    respond_to do |format|
      if @message && @message.save
        flash[:notice] = "Message was successfully received."
        format.xml {render :xml => @message, :status => :created}
      else
        flash[:notice]= "Oops, we had an error reading this message."
        format.xml {render :xml => @message ? @message.errors : {code: -1, message: "unparseable"}, :status => :unprocessable_entity}
      end
    end
  end
  
  protected
  
  def clean_fields
    params["from"]    = clean_field(params["from"])
    params["to"]      = clean_field(params["to"])
    params["cc"]      = clean_field(params["cc"])
    params["subject"] = clean_field(params["subject"])
  end
  
  def clean_field(input_string)
    input_string.gsub(/\n/, "") if input_string
  end
  
  def message_params
    params.permit(:text, :html, :from, :to, :cc, :subject)
  end
end
