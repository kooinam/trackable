module Api
  module Trackable
    extend ActiveSupport::Concern

    included do
      skip_before_action :verify_authenticity_token
    end

    protected
    def invalid_resource!(resource)
      Rails.logger.error "invalid_resouce_errors=#{resource.errors.full_messages}"
      @resource = resource
      render json: {
        errors: resource.errors.to_hash
      }, status: 422
    end

    def unauthorized
      render json: { error: 'Unauthorized' }, status: 401
    end

    def access_denied
      render json: { error: 'Access Denied' }, status: 403
    end

    def render_not_found
      render json: {
        errors: {
          base: ['Not found']
        },
      }, status: 404
    end

    def render_not_found(item)
      @item = item
      @camelize = true

      render 'api/not_found', status: 404
    end

    def mongoid_ransack(scope)
      scope = MongoidRansack.ransack(scope, q: q_params)

      scope
    end

    def paginate(resource)
      current_page = params[:page] || 1
      per_page = params[:per_page] || 10

      resource.page(current_page).per(per_page)
    end

    def get_params(symbol, permitted_attributes)
      permitted_params = (params[symbol].blank?)? {} : params.require(symbol).permit(permitted_attributes)

      permitted_params
    end

    def q_params
      try_params(:q)
    end

    def try_params(symbol)
      res = params[symbol]
      if res.is_a? String
        res = JSON.parse(res)
        res = HashWithIndifferentAccess.new(res)
      end

      res || {}
    end

    private
    def user_agent
      request.headers['User-Agent']
    end

    def trackable_session_params
      client = DeviceDetector.new(user_agent)

      res = {}
      res[:ip] = request.remote_ip
      res[:ua] = user_agent
      res[:browser] = client.name
      res[:os_family] = client.os_name
      res[:os_version] = client.os_full_version
      res[:device_name] = client.device_name
      res[:device_type] = client.device_type
      res[:locale] = I18n.locale

      res
    end
  end
end
