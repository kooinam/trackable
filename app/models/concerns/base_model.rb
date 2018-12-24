module BaseModel
  extend ActiveSupport::Concern

  included do
    include Mongoid::Document
    include Mongoid::Timestamps
    include MongoidEnumerable
  end

  class_methods do
    def has_many_through_1(children, middles, class_name: nil)
      define_method children do
        ids = self.send(middles).map do |middle|
          middle.send("#{children.to_s.singularize.to_sym}_id".to_sym)
        end

        associations = nil

        if class_name
          associations = class_name.constantize.where(:id.in => ids)
        else
          associations = children.to_s.singularize.camelize.constantize.where(:id.in => ids)
        end

        associations
      end
    end

    def has_many_through_2(children, middles, class_name: nil)
      define_method children do
        ids = self.send(middles).map(&:id)

        associations = nil

        if class_name
          associations = class_name.constantize.where("#{middles.to_s.singularize}_id".to_sym.in => ids)
        else
          associations = children.to_s.singularize.camelize.constantize.where("#{middles.to_s.singularize}_id".to_sym.in => ids)
        end

        associations
      end
    end
  end
end
