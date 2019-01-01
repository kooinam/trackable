module ReferenceNumber
  extend ActiveSupport::Concern

  included do
    before_validation :assign_reference_number, on: :create
  end

  private
  def reference_number_length
    9
  end

  def reference_number_letters
    true
  end

  def reference_number_prefix
    'R'
  end

  def assign_reference_number(options = {})
    options[:length]  ||= reference_number_length
    options[:letters] ||= reference_number_letters
    options[:prefix]  ||= reference_number_prefix

    possible = (0..9).to_a
    possible += ('A'..'Z').to_a if options[:letters]
    possible += ('a'..'z').to_a if options[:letters]

    self.reference_number ||= loop do
      # Make a random number.
      random = "#{options[:prefix]}#{(0...options[:length]).map { possible.sample }.join}"
      # Use the random  number if no other order exists with it.
      if self.class.exists?(number: random)
        # If over half of all possible options are taken add another digit.
        options[:length] += 1 if self.class.count > (10**options[:length] / 2)
      else
        break random
      end
    end
  end
end