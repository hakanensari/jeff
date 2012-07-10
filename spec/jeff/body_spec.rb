require 'spec_helper'

module Jeff
  describe Body do
    let(:io) do
      StringIO.new %{
        <?xml version=\"1.0\" ?>
        <ItemAttributes>
          <Title>Anti-Oedipus</Title>
          <Author>Gilles Deleuze</Author>
          <Author>Felix Guattari</Author>
          <Creator Role="Translator">Robert Hurley</Creator>
        </ItemAttributes>
      }.strip.gsub />\s+</, '><'
    end

    let(:body) { described_class.new }
    let(:parser) { Nokogiri::XML::SAX::Parser.new body }

    before do
      io.rewind
      parser.parse io
    end

    describe '#root' do
      subject { body.root['ItemAttributes'] }

      it { should be_a Hash }

      it 'should handle only children' do
        subject['Title'].should eql 'Anti-Oedipus'
      end

      it 'should hande arrays' do
        subject['Author'].should be_an Array
      end

      it 'should handle attributes' do
        creator = subject['Creator']
        creator['Role'].should eql 'Translator'
        creator['__content__'].should eql 'Robert Hurley'
      end
    end
  end
end
