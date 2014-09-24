class Api::TagsController < Api::ApplicationController
  
  # [GET] /api/tags(.:format)
  def index
    @tags = ActsAsTaggableOn::Tag.filter(params)
    respond_with @tags
  end

  # [GET] /api/tags/count(.:format)
  def count
    render :json => {:count => ActsAsTaggableOn::Tag.filter(params).count}
  end
  
end
