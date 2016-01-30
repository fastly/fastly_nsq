require 'test_helper'
require 'fastly_nsq'

describe FastlyNsq do
  it 'has a version number' do
    version = FastlyNsq.const_get('VERSION')

    assert(!version.empty?, 'should have a VERSION constant')
  end
end
