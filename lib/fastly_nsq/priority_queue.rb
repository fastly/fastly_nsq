# frozen_string_literal: true

class FastlyNsq::PriorityQueue < FastContainers::PriorityQueue
  alias_method :<<, :push
  alias_method :length, :size

  def shift
    pop
  rescue RuntimeError
    nil
  end
end
