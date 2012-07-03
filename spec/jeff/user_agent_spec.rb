require 'spec_helper'

module Jeff
  describe UserAgent do
    subject { UserAgent::USER_AGENT }

    it 'describes the library' do
      should match /Jeff\/[\d\w.]+\s/
    end

    it 'describes the interpreter' do
      should match /Language=(?:j?ruby|rbx)/
    end

    it 'describes the host' do
      should match /Host=[\w\d]+/
    end
  end
end
