# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe ParagraphSerializer do
      subject do
        described_class.new(paragraph)
      end

      let!(:paragraph) { create(:paragraph, :accepted) }
      let!(:category) { create(:category, participatory_space: component.participatory_space) }
      let!(:scope) { create(:scope, organization: component.participatory_space.organization) }
      let(:participatory_process) { component.participatory_space }
      let(:component) { paragraph.component }

      let!(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
      let(:meetings) { create_list(:meeting, 2, component: meetings_component) }

      let!(:paragraphs_component) { create(:component, manifest_name: "paragraphs", participatory_space: participatory_process) }
      let(:other_paragraphs) { create_list(:paragraph, 2, component: paragraphs_component) }

      let(:expected_answer) do
        answer = paragraph.answer
        Decidim.available_locales.each_with_object({}) do |locale, result|
          result[locale.to_s] = if answer.is_a?(Hash)
                                  answer[locale.to_s] || ""
                                else
                                  ""
                                end
        end
      end

      before do
        paragraph.update!(category: category)
        paragraph.update!(scope: scope)
        paragraph.link_resources(meetings, "paragraphs_from_meeting")
        paragraph.link_resources(other_paragraphs, "copied_from_component")
      end

      describe "#serialize" do
        let(:serialized) { subject.serialize }

        it "serializes the id" do
          expect(serialized).to include(id: paragraph.id)
        end

        it "serializes the category" do
          expect(serialized[:category]).to include(id: category.id)
          expect(serialized[:category]).to include(name: category.name)
        end

        it "serializes the scope" do
          expect(serialized[:scope]).to include(id: scope.id)
          expect(serialized[:scope]).to include(name: scope.name)
        end

        it "serializes the title" do
          expect(serialized).to include(title: paragraph.title)
        end

        it "serializes the body" do
          expect(serialized).to include(body: paragraph.body)
        end

        it "serializes the amount of supports" do
          expect(serialized).to include(supports: paragraph.paragraph_votes_count)
        end

        it "serializes the amount of comments" do
          expect(serialized).to include(comments: paragraph.comments_count)
        end

        it "serializes the date of creation" do
          expect(serialized).to include(published_at: paragraph.published_at)
        end

        it "serializes the url" do
          expect(serialized[:url]).to include("http", paragraph.id.to_s)
        end

        it "serializes the component" do
          expect(serialized[:component]).to include(id: paragraph.component.id)
        end

        it "serializes the meetings" do
          expect(serialized[:meeting_urls].length).to eq(2)
          expect(serialized[:meeting_urls].first).to match(%r{http.*/meetings})
        end

        it "serializes the participatory space" do
          expect(serialized[:participatory_space]).to include(id: participatory_process.id)
          expect(serialized[:participatory_space][:url]).to include("http", participatory_process.slug)
        end

        it "serializes the state" do
          expect(serialized).to include(state: paragraph.state)
        end

        it "serializes the reference" do
          expect(serialized).to include(reference: paragraph.reference)
        end

        it "serializes the answer" do
          expect(serialized).to include(answer: expected_answer)
        end

        it "serializes the amount of attachments" do
          expect(serialized).to include(attachments: paragraph.attachments.count)
        end

        it "serializes the endorsements" do
          expect(serialized[:endorsements]).to include(total_count: paragraph.endorsements.count)
          expect(serialized[:endorsements]).to include(user_endorsements: paragraph.endorsements.for_listing.map { |identity| identity.normalized_author&.name })
        end

        it "serializes related paragraphs" do
          expect(serialized[:related_paragraphs].length).to eq(2)
          expect(serialized[:related_paragraphs].first).to match(%r{http.*/paragraphs})
        end

        it "serializes if paragraph is_amend" do
          expect(serialized).to include(is_amend: paragraph.emendation?)
        end

        it "serializes the original paragraph" do
          expect(serialized[:original_paragraph]).to include(title: paragraph&.amendable&.title)
          expect(serialized[:original_paragraph][:url]).to be_nil || include("http", paragraph.id.to_s)
        end

        context "with paragraph having an answer" do
          let!(:paragraph) { create(:paragraph, :with_answer) }

          it "serializes the answer" do
            expect(serialized).to include(answer: expected_answer)
          end
        end
      end
    end
  end
end
