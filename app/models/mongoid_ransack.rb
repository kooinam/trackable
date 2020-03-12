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
      Mongoid.logger.level = Logger::INFO

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
        if scope.klass.fields.keys.include? filter and scope.klass.fields[filter].type == Object
          scope = scope.where("#{filter}" => q[filter])
        elsif scope.klass.fields.keys.include? filter and scope.klass.fields[filter].type == Integer
          scope = scope.where("#{filter}" => q[filter].try(:to_i))
        elsif scope.klass.fields.keys.include? filter and scope.klass.fields[filter].type == String
          scope = scope.where("#{filter}" => /#{q[filter]}/i)
        elsif (filter == 'id') and (q[filter].blank? == false)
          scope = scope.where(id: q[filter])
        elsif scope.klass.fields.keys.include? filter and scope.klass.fields[filter].type == Mongoid::Boolean
          if q[filter] == 'true'
            scope = scope.where("#{filter}" => true)
          elsif q[filter] == 'false'
            scope = scope.where("#{filter}" => false)
          end
        elsif filter.to_s.include? '_gteq'
          scope = self.filter_gteq(scope, filter, q[filter])
        elsif filter.to_s.include? '_lteq'
          scope = self.filter_lteq(scope, filter, q[filter])
        end
      end
    end

    scope
  end

  def self.filter_gteq(scope, filter, value)
    filter = filter.to_s.gsub('_gteq', '')

    if scope.klass.fields.keys.include? filter and (scope.klass.fields[filter].type == Time or scope.klass.fields[filter].type == DateTime)
      scope = scope.where(filter.to_sym.gte => Time.zone.parse(value).beginning_of_day)
    end

    scope
  end

  def self.filter_lteq(scope, filter, value)
    filter = filter.to_s.gsub('_lteq', '')

    if scope.klass.fields.keys.include? filter and (scope.klass.fields[filter].type == Time or scope.klass.fields[filter].type == DateTime)
      scope = scope.where(filter.to_sym.lte => Time.zone.parse(value).end_of_day)
    end

    scope
  end
end
