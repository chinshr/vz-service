class Web::ExplorersController < Web::ApplicationController

  def index
  end

  def show
    load_tag
  end

  protected

  def load_tag
    @tag = ActsAsTaggableOn::Tag.find_by_slug!(params[:id])
  end
end
