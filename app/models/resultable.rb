class Resultable
  attr_accessor :errors, :parameters, :message, :results, :data

  def initialize
    self.errors = {}
    self.parameters = {}
    self.data = {}
  end

  def add_error(key, value)
    self.errors[key] ||= []
    self.errors[key].push(value)
  end

  def success?
    self.errors.empty?
  end

  def failed?
    self.errors.empty? == false
  end

  def set_data(data)
    self.data = data
  end
end