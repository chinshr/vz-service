class Web::ExplorersController < Web::ApplicationController

  def index
  end

  def show
    load_tag
  end

  protected

  def load_tag
    # @tag = ActsAsTaggableOn::Tag.slugged_like(params[:id]).most_used.first!
    @tag = ActsAsTaggableOn::Tag.find_by_slug!(params[:id])
  end
end
