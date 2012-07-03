require 'spec_helper'

describe Jeff do
  describe '.new' do
    it 'delegates to Client' do
      Jeff.new('http://foo').should be_a Jeff::Client
    end
  end
end
