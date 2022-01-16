# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentRenderers
    describe ParagraphRenderer do
      let!(:renderer) { Decidim::ContentRenderers::ParagraphRenderer.new(content) }

      describe "on parse" do
        subject { renderer.render }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }
        end

        context "when conent has no gids" do
          let(:content) { "whatever content with @mentions and #hashes but no gids." }

          it { is_expected.to eq(content) }
        end

        context "when content has one gid" do
          let(:paragraph) { create(:paragraph) }
          let(:content) do
            "This content references paragraph #{paragraph.to_global_id}."
          end

          it { is_expected.to eq("This content references paragraph #{paragraph_as_html_link(paragraph)}.") }
        end

        context "when content has many links" do
          let(:paragraph_1) { create(:paragraph) }
          let(:paragraph_2) { create(:paragraph) }
          let(:paragraph_3) { create(:paragraph) }
          let(:content) do
            gid1 = paragraph_1.to_global_id
            gid2 = paragraph_2.to_global_id
            gid3 = paragraph_3.to_global_id
            "This content references the following paragraphs: #{gid1}, #{gid2} and #{gid3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following paragraphs: #{paragraph_as_html_link(paragraph_1)}, #{paragraph_as_html_link(paragraph_2)} and #{paragraph_as_html_link(paragraph_3)}. Great?I like them!") }
        end
      end

      def paragraph_url(paragraph)
        Decidim::ResourceLocatorPresenter.new(paragraph).path
      end

      def paragraph_as_html_link(paragraph)
        href = paragraph_url(paragraph)
        title = translated(paragraph.title)
        %(<a href="#{href}">#{title}</a>)
      end
    end
  end
end
