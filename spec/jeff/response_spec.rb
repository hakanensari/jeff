require 'spec_helper'

module Jeff
  describe Response do
    let(:chunks) { %w(foo bar baz) }
    let(:response) { Response.new }

    context 'given a chunked HTTP response in a thread' do
      before do
        Thread.new {
          chunks.each { |chunk| response << chunk }
          response.close
          response.status = 200
        }
      end

      describe '#status' do
        it 'should return the status' do
          response.status.should be 200
        end
      end

      describe '#read' do
        it 'should return the body' do
          body = ''
          loop do
            body << response.readpartial(1)
            break if response.eof?
          end

          body.should eql chunks.join
        end
      end
    end
  end
end
