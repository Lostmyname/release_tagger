require 'spec_helper'

describe ReleaseTagger do
  it 'has a version number' do
    expect(ReleaseTagger::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
