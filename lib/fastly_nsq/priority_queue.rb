# frozen_string_literal: true

class FastlyNsq::PriorityQueue < FastContainers::PriorityQueue
  alias << push
  alias length size

  def shift
    pop
  rescue RuntimeError
    nil
  end
end
