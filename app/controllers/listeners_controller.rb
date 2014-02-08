# /listener/receive_email.xml
class ListenersController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :clean_fields
  
  def receive_email
    with Employee.find_by_email(params["from"]) do |employee|
      @message = Request::Message.build(params) do |m|
        m.employee = employee
      end
    end
    
    respond_to do |format|
      if @message && @message.save
        @message.process!
        flash[:notice] = "Item was successfully created."
        format.xml {render :xml => @message, :status => :created}
      else
        flash[:notice]= "Oops, we had an error saving the item."
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
  
end
