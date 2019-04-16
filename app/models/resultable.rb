class Resultable
  attr_accessor :errors, :parameters, :message, :results

  def initialize
    self.errors = {}
    self.parameters = {}
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
end