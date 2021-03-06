require 'rails_helper'

RSpec.describe Section, type: :model do

  let!(:section) { Fabricate(:section) }
  let!(:section_home) { Fabricate(:section_home, section: section) }

  it { is_expected.to have_many :nodes }

  describe '#users' do
    context 'section with no users' do
      it 'returns no users' do
        expect(section.users).to eq []
      end
    end

    context 'section with an author user' do
      let!(:author) { Fabricate(:user, author_of: section) }
      let!(:other_section) { Fabricate(:section) }
      let!(:other_author) { Fabricate(:user, author_of: other_section) }
      it 'returns author user' do
        expect(section.users).to eq [author]
      end
    end
  end

  describe 'home node' do
    subject { section.home_node }

    it { is_expected.to be_present }
    it { is_expected.to be_a SectionHome }

    it 'should have an appropriate slug' do
      expect(subject.slug).to eq section.name.parameterize
    end

    it 'should be a child of the root node' do
      expect(subject.parent).to eq Node.root_node
    end
  end

  describe '#name' do
    let(:section) { Fabricate(:section, name: 'original') }
    it do
      expect{ section.home_node.update(name: 'updated') }.to(
        change{section.reload.name}.from('original').to('updated'))
    end
  end
end
