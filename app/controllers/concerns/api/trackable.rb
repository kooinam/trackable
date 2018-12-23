module Api
  module Trackable
    extend ActiveSupport::Concern

    included do
      skip_before_action :verify_authenticity_token
    end

    protected
    def mongoid_ransack(scope)
      s =  (q_params[:s]) ? q_params[:s][0] : nil

      if s
        scope = scope.order(s)
      end

      filters = []
      q_params.each do |key, value|
        filters.push(key)
      end
      filters.each do |filter|
        if filter.to_s.include?('.')
          association_and_field = filter.to_s.split('.')
          association = association_and_field[0]
          field = association_and_field[1]

          association_ids = []
          scope.klass.reflect_on_all_associations(:belongs_to).each do |belongs_to|
            if belongs_to.name.to_s == association
              association_ids = belongs_to.class_name.constantize.where("#{field}" => /#{q_params[filter]}/i).map(&:id)
            end
          end

          scope = scope.where("#{association}".to_sym.in => association_ids)
        else
          if scope.klass.fields.keys.include? filter and scope.klass.fields[filter].type == String
            scope = scope.where("#{filter}" => /#{q_params[filter]}/i)
          end
        end
      end

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
