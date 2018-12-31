class EagerLoader
  def self.load(collection, *args)
    args.each do |arg|
      arg_id = "#{arg}_id".to_sym
      arg_ids = collection.map do |record|
        record.send(arg_id)
      end

      relations = arg.to_s.singularize.camelize.constantize.where(:id.in => arg_ids)
      relations = relations.index_by(&:id)

      collection = collection.map do |record|
        record.set_relation(arg, relations[record.send(arg_id)])

        record
      end
    end

    collection
  end
end
