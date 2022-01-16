# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentParsers
    describe ParagraphParser do
      let(:organization) { create(:organization) }
      let(:component) { create(:paragraph_component, organization: organization) }
      let(:context) { { current_organization: organization } }
      let!(:parser) { Decidim::ContentParsers::ParagraphParser.new(content, context) }

      describe "ContentParser#parse is invoked" do
        let(:content) { "" }

        it "must call ParagraphParser.parse" do
          expect(described_class).to receive(:new).with(content, context).and_return(parser)

          result = Decidim::ContentProcessor.parse(content, context)

          expect(result.rewrite).to eq ""
          expect(result.metadata[:paragraph].class).to eq Decidim::ContentParsers::ParagraphParser::Metadata
        end
      end

      describe "on parse" do
        subject { parser.rewrite }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to eq([])
          end
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to eq([])
          end
        end

        context "when conent has no links" do
          let(:content) { "whatever content with @mentions and #hashes but no links." }

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to eq([])
          end
        end

        context "when content links to an organization different from current" do
          let(:paragraph) { create(:paragraph, component: component) }
          let(:external_paragraph) { create(:paragraph, component: create(:paragraph_component, organization: create(:organization))) }
          let(:content) do
            url = paragraph_url(external_paragraph)
            "This content references paragraph #{url}."
          end

          it "does not recognize the paragraph" do
            subject
            expect(parser.metadata.linked_paragraphs).to eq([])
          end
        end

        context "when content has one link" do
          let(:paragraph) { create(:paragraph, component: component) }
          let(:content) do
            url = paragraph_url(paragraph)
            "This content references paragraph #{url}."
          end

          it { is_expected.to eq("This content references paragraph #{paragraph.to_global_id}.") }

          it "has metadata with the paragraph" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to eq([paragraph.id])
          end
        end

        context "when content has one link that is a simple domain" do
          let(:link) { "aaa:bbb" }
          let(:content) do
            "This content contains #{link} which is not a URI."
          end

          it { is_expected.to eq(content) }

          it "has metadata with the paragraph" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to be_empty
          end
        end

        context "when content has many links" do
          let(:paragraph1) { create(:paragraph, component: component) }
          let(:paragraph2) { create(:paragraph, component: component) }
          let(:paragraph3) { create(:paragraph, component: component) }
          let(:content) do
            url1 = paragraph_url(paragraph1)
            url2 = paragraph_url(paragraph2)
            url3 = paragraph_url(paragraph3)
            "This content references the following paragraphs: #{url1}, #{url2} and #{url3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following paragraphs: #{paragraph1.to_global_id}, #{paragraph2.to_global_id} and #{paragraph3.to_global_id}. Great?I like them!") }

          it "has metadata with all linked paragraphs" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to eq([paragraph1.id, paragraph2.id, paragraph3.id])
          end
        end

        context "when content has a link that is not in a paragraphs component" do
          let(:paragraph) { create(:paragraph, component: component) }
          let(:content) do
            url = paragraph_url(paragraph).sub(%r{/paragraphs/}, "/something-else/")
            "This content references a non-paragraph with same ID as a paragraph #{url}."
          end

          it { is_expected.to eq(content) }

          it "has metadata with no reference to the paragraph" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to be_empty
          end
        end

        context "when content has words similar to links but not links" do
          let(:similars) do
            %w(AA:aaa AA:sss aa:aaa aa:sss aaa:sss aaaa:sss aa:ssss aaa:ssss)
          end
          let(:content) do
            "This content has similars to links: #{similars.join}. Great! Now are not treated as links"
          end

          it { is_expected.to eq(content) }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to be_empty
          end
        end

        context "when paragraph in content does not exist" do
          let(:paragraph) { create(:paragraph, component: component) }
          let(:url) { paragraph_url(paragraph) }
          let(:content) do
            paragraph.destroy
            "This content references paragraph #{url}."
          end

          it { is_expected.to eq("This content references paragraph #{url}.") }

          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to eq([])
          end
        end

        context "when paragraph is linked via ID" do
          let(:paragraph) { create(:paragraph, component: component) }
          let(:content) { "This content references paragraph ~#{paragraph.id}." }

          it { is_expected.to eq("This content references paragraph #{paragraph.to_global_id}.") }

          it "has metadata with the paragraph" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::ParagraphParser::Metadata)
            expect(parser.metadata.linked_paragraphs).to eq([paragraph.id])
          end
        end
      end

      def paragraph_url(paragraph)
        Decidim::ResourceLocatorPresenter.new(paragraph).url
      end
    end
  end
end
