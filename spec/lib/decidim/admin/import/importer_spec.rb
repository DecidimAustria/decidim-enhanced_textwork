# frozen_string_literal: true

require "spec_helper"

describe Decidim::Admin::Import::Importer do
  subject { described_class.new(file: file, reader: reader, creator: creator, context: context) }

  let(:creator) { Decidim::EnhancedTextwork::ParagraphCreator }

  let(:organization) { create(:organization, available_locales: [:en]) }
  let(:user) { create(:user, organization: organization) }
  let(:context) do
    {
      current_organization: organization,
      current_user: user,
      current_component: current_component,
      current_participatory_space: participatory_process
    }
  end
  let(:participatory_process) { create :participatory_process, organization: organization }
  let(:current_component) { create :component, manifest_name: :paragraphs, participatory_space: participatory_process }

  context "with CSV" do
    let(:file) { File.new Decidim::Dev.asset("import_paragraphs.csv") }
    let(:reader) { Decidim::Admin::Import::Readers::CSV }

    it_behaves_like "paragraph importer"

    describe "#prepare" do
      it "makes an array of new paragraphs" do
        expect(subject.prepare).to be_an_instance_of(Array)
        expect(subject.prepare).not_to be_empty
        expect(subject.prepare).to all(be_a_instance_of(Decidim::EnhancedTextwork::Paragraph))
      end
    end

    describe "#import" do
      it "saves the paragraphs" do
        subject.prepare
        expect do
          subject.import!
        end.to change(Decidim::EnhancedTextwork::Paragraph, :count).by(3)
      end
    end

    describe "#invalid_lines" do
      it "returns empty array when everything is ok" do
        subject.prepare
        expect(subject.invalid_lines).to be_empty
      end

      it "returns index+1 of erroneous resource when validations faild" do
        paragraph = subject.prepare.first
        paragraph.title = ""
        subject.instance_variable_set(:@prepare, [paragraph])
        expect(subject.invalid_lines).to eq([1])
      end
    end
  end

  context "with JSON" do
    let(:file) { File.new Decidim::Dev.asset("import_paragraphs.json") }
    let(:reader) { Decidim::Admin::Import::Readers::JSON }

    it_behaves_like "paragraph importer"
  end

  context "with XLSX" do
    let(:file) { File.new Decidim::Dev.asset("import_paragraphs.xlsx") }
    let(:reader) { Decidim::Admin::Import::Readers::XLSX }

    it_behaves_like "paragraph importer"
  end
end
