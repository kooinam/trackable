class EagerLoader
  attr_accessor :all, :total_count

  def self.load(collection, *args)
    eager_loader = EagerLoader.new
    eager_loader.all = []
    eager_loader.total_count = collection.try(:total_count)

    args.each do |arg|
      arg_id = "#{arg}_id".to_sym
      arg_ids = collection.map do |record|
        record.send(arg_id)
      end

      relations = arg.to_s.singularize.camelize.constantize.where(:id.in => arg_ids)
      relations = relations.index_by(&:id)

      eager_loader.all = collection.map do |record|
        record.set_relation(arg, relations[record.send(arg_id)])

        record
      end
    end

    eager_loader
  end

  def each(&proc)
    @all.each(&proc)
  end

  def map(&proc)
    @all.map(&proc)
  end
end
