module Api::Require
  
  def self.included(base, *params)
    base.send :include, InstanceMethods
    base.before_filter :require_param_id, :only => [:show, :update, :destroy]
  end

  module InstanceMethods

    def require_param_id
      params.require(:id)
      # raise Api::Exception::ArgumentMissing.new(:id) unless params.has_key?(:id)
    end

  end

end