# frozen_string_literal: true

class FastlyNsq::PriorityQueue < FastContainers::PriorityQueue
  alias << push
  alias length size
  alias shift pop
end
