# frozen_string_literal: true

RSpec.describe BlockRepeater do
  it 'has a version number' do
    expect(BlockRepeater::VERSION).not_to be nil
  end

  it 'has a Gemfile.lock version that matches the gem version' do
    lockfile = File.read(File.expand_path('../Gemfile.lock', __dir__))
    lockfile_version = lockfile.match(/block_repeater \((\d+\.\d+\.\d+)\)/)&.captures&.first
    expect(lockfile_version).to eq(BlockRepeater::VERSION)
  end
end
