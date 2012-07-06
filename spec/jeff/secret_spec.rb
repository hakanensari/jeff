require 'spec_helper'

module Jeff
  describe Secret do
    let(:secret) { Secret.new 'key' }

    describe '#sign' do
      after { secret.sign 'message' }

      it 'should digest' do
        secret.should_receive(:digest)
              .and_return double.as_null_object
      end
      it 'should Base64-encode' do
        Base64.should_receive(:encode64)
              .and_return double.as_null_object
      end
    end
  end
end
