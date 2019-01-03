class EagerLoader
  attr_accessor :all, :total_count

  def self.load(collection, *args)
    eager_loader = EagerLoader.new
    eager_loader.all = collection.to_a
    eager_loader.total_count = collection.try(:total_count)

    args.each do |arg|
      if arg.is_a? Hash
        arg.keys.each do |key|
          eager_loader.all = self.set_relation(eager_loader.all, key)

          arg[key].each do |nested_key|
            nested_all = eager_loader.all.map do |record|
              record.send(key)
            end

            nested_all = self.set_relation(nested_all, nested_key)
          end
        end
      else
        eager_loader.all = self.set_relation(eager_loader.all, arg)
      end
    end

    eager_loader
  end

  def self.set_relation(records, key)
    key_id = "#{key}_id".to_sym
    key_ids = records.map do |record|
      record.send(key_id)
    end

    relations = key.to_s.singularize.camelize.constantize.where(:id.in => key_ids)
    relations = relations.index_by(&:id)

    records = records.map do |record|
      record.set_relation(key, relations[record.send(key_id)])

      record
    end

    records
  end

  def each(&proc)
    @all.each(&proc)
  end

  def map(&proc)
    @all.map(&proc)
  end
end
