require 'spec_helper'

module Jeff
  describe Document do
    let(:io) do
      StringIO.new %{
        <?xml version=\"1.0\" ?>
        <ItemAttributes>
          <Title>Anti-Oedipus</Title>
          <Author>Gilles Deleuze</Author>
          <Author>Felix Guattari</Author>
          <Creator Role="Translator">Robert Hurley</Creator>
        </ItemAttributes>
      }.strip
    end

    let(:doc) { described_class.new }
    let(:parser) { Nokogiri::XML::SAX::Parser.new doc }

    before do
      io.rewind
      parser.parse io
    end

    describe '#root' do
      subject { doc.root['ItemAttributes'] }

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

      it 'should ignore space between tags' do
        should_not have_key '__content__'
      end
    end
  end
end
