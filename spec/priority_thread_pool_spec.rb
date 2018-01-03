# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FastlyNsq::PriorityThreadPool do
  let!(:pool) { described_class.new(max_threads: 20) }

  after { pool.shutdown || pool.wait_for_termination }

  it 'executes work based on supplied priority' do
    actual = []
    count = 100
    count.times { |i| pool.post(i) { actual << i } }
    expect { pool.completed_task_count }.to eventually(eq(count)).within(5)

    # weak but stable assertion that the last element was not the last processed
    expect(actual.last).not_to eq(count - 1)
  end
end
