class MongoidRansack
  def self.ransack(scope, q: {})
    s =  (q[:s]) ? q[:s][0] : nil

    if s
      scope = scope.order(s)
    end

    filters = []
    q.each do |key, value|
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
            association_ids = belongs_to.class_name.constantize.where("#{field}" => /#{q[filter]}/i).map(&:id)
          end
        end

        scope = scope.where("#{association}".to_sym.in => association_ids)
      else
        if scope.klass.fields.keys.include? filter and scope.klass.fields[filter].type == String
          scope = scope.where("#{filter}" => /#{q[filter]}/i)
        end
      end
    end

    scope
  end
end
