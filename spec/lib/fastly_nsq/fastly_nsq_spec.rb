require 'spec_helper'
require 'fastly_nsq'

RSpec.describe FastlyNsq do
  it 'has a version number' do
    version = FastlyNsq.const_get('VERSION')

    expect(version).not_to be_empty
  end
end
