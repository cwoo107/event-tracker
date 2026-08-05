module Initialing
  extend ActiveSupport::Concern

  # "Caleb Bennett" -> "CB". Relies on the including model having a #name.
  def initials
    name.to_s.split.map { |word| word[0] }.join.upcase
  end
end
