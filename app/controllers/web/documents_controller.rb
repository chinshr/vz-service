class Web::DocumentsController < ApplicationController
  
  def show
    @document = Document.where(slug: params[:id]).first!
  end

  def edit
    @document = Document.where(slug: params[:id]).first!
  end
  
end
