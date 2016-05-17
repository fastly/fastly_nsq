require 'spec_helper'

RSpec.describe FastlyNsq do
  module TestStrategy; end

  it 'allows the logger to be set and retrieved' do
    logger = Logger.new(STDOUT)
    FastlyNsq.logger = logger

    expect(FastlyNsq.logger).to eq logger
  end

  it 'returns the current Strategy' do
    allow(FastlyNsq::Strategy).to receive(:for_queue).and_return(TestStrategy)

    expect(FastlyNsq.strategy).to eql(TestStrategy)
  end
end
