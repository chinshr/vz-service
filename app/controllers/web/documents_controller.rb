class Web::DocumentsController < ApplicationController
  before_filter :load_document!, :only => [:show, :edit]
  before_filter :authenticate_user!, :if => :document_private?
  
  def show
    @document = Document.where(slug: params[:id]).first!
  end

  def edit
    @document = Document.where(slug: params[:id]).first!
  end
  
  protected
  
  def load_document!
    @document = Document.where(slug: params[:id]).first!
  end
  
  def document_private?
    @document.privacy.include?(:private)
  end
  
end
