module Api::Limit
  def self.included(base, *params)
    base.send :include, InstanceMethods
    base.before_filter :limit_parameter
  end

  module InstanceMethods
    def limit_parameter
      params[:limit] = 25 unless params.has_key?(:limit) #default is 25
      if ENV["MAX_RESPONSE_LIMIT"].present? && params[:limit].to_i > ENV["MAX_RESPONSE_LIMIT"].to_i 
        params[:limit] = ENV["MAX_RESPONSE_LIMIT"].to_i 
      elsif ENV["MAX_RESPONSE_LIMIT"].blank? && params[:limit].to_i > 50 
        params[:limit] = 50
      end
    end
  end
end