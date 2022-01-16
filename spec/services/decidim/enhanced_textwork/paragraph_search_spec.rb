# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe ParagraphSearch do
      subject { described_class.new(params).results }

      let(:component) { create(:component, manifest_name: "paragraphs") }
      let(:default_params) { { component: component, user: user } }
      let(:params) { default_params }
      let(:participatory_process) { component.participatory_space }
      let(:user) { create(:user, organization: component.organization) }

      it_behaves_like "a resource search", :paragraph
      it_behaves_like "a resource search with scopes", :paragraph
      it_behaves_like "a resource search with categories", :paragraph
      it_behaves_like "a resource search with origin", :paragraph

      describe "results" do
        let!(:paragraph) { create(:paragraph, component: component) }

        describe "search_text filter" do
          let(:params) { default_params.merge(search_text: search_text) }
          let(:search_text) { "dog" }

          it "returns the paragraphs containing the search in the title or the body" do
            create_list(:paragraph, 3, component: component)
            create(:paragraph, title: "A dog", component: component)
            create(:paragraph, body: "There is a dog in the office", component: component)

            expect(subject.size).to eq(2)
          end
        end

        describe "activity filter" do
          let(:params) { default_params.merge(activity: activity) }

          context "when filtering by supported" do
            let(:activity) { "voted" }

            it "returns the paragraphs voted by the user" do
              create_list(:paragraph, 3, component: component)
              create(:paragraph_vote, paragraph: Paragraph.first, author: user)

              expect(subject.size).to eq(1)
            end
          end

          context "when filtering by my paragraphs" do
            let(:activity) { "my_paragraphs" }

            it "returns the paragraphs created by the user" do
              create_list(:paragraph, 3, component: component)
              create(:paragraph, component: component, users: [user])

              expect(subject.size).to eq(1)
            end
          end
        end

        describe "state filter" do
          let(:params) { default_params.merge(state: states) }

          context "when filtering for default states" do
            let(:states) { [] }

            it "returns all except withdrawn paragraphs" do
              create_list(:paragraph, 3, :withdrawn, component: component)
              other_paragraphs = create_list(:paragraph, 3, component: component)
              other_paragraphs << paragraph

              expect(subject.size).to eq(4)
              expect(subject).to match_array(other_paragraphs)
            end
          end

          context "when filtering :except_rejected paragraphs" do
            let(:states) { %w(accepted evaluating state_not_published) }

            it "hides withdrawn and rejected paragraphs" do
              create(:paragraph, :withdrawn, component: component)
              create(:paragraph, :rejected, component: component)
              accepted_paragraph = create(:paragraph, :accepted, component: component)

              expect(subject.size).to eq(2)
              expect(subject).to match_array([accepted_paragraph, paragraph])
            end
          end

          context "when filtering accepted paragraphs" do
            let(:states) { %w(accepted) }

            it "returns only accepted paragraphs" do
              accepted_paragraphs = create_list(:paragraph, 3, :accepted, component: component)
              create_list(:paragraph, 3, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(accepted_paragraphs)
            end
          end

          context "when filtering rejected paragraphs" do
            let(:states) { %w(rejected) }

            it "returns only rejected paragraphs" do
              create_list(:paragraph, 3, component: component)
              rejected_paragraphs = create_list(:paragraph, 3, :rejected, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(rejected_paragraphs)
            end
          end

          context "when filtering withdrawn paragraphs" do
            let(:params) { default_params.merge(state_withdraw: state_withdraw) }
            let(:state_withdraw) { "withdrawn" }

            it "returns only withdrawn paragraphs" do
              create_list(:paragraph, 3, component: component)
              withdrawn_paragraphs = create_list(:paragraph, 3, :withdrawn, component: component)

              expect(subject.size).to eq(3)
              expect(subject).to match_array(withdrawn_paragraphs)
            end
          end
        end

        describe "related_to filter" do
          let(:params) { default_params.merge(related_to: related_to) }

          context "when filtering by related to meetings" do
            let(:related_to) { "Decidim::Meetings::Meeting".underscore }
            let(:meetings_component) { create(:component, manifest_name: "meetings", participatory_space: participatory_process) }
            let(:meeting) { create :meeting, component: meetings_component }

            it "returns only paragraphs related to meetings" do
              related_paragraph = create(:paragraph, :accepted, component: component)
              related_paragraph2 = create(:paragraph, :accepted, component: component)
              create_list(:paragraph, 3, component: component)
              meeting.link_resources([related_paragraph], "paragraphs_from_meeting")
              related_paragraph2.link_resources([meeting], "paragraphs_from_meeting")

              expect(subject).to match_array([related_paragraph, related_paragraph2])
            end
          end

          context "when filtering by related to resources" do
            let(:related_to) { "Decidim::DummyResources::DummyResource".underscore }
            let(:dummy_component) { create(:component, manifest_name: "dummy", participatory_space: participatory_process) }
            let(:dummy_resource) { create :dummy_resource, component: dummy_component }

            it "returns only paragraphs related to results" do
              related_paragraph = create(:paragraph, :accepted, component: component)
              related_paragraph2 = create(:paragraph, :accepted, component: component)
              create_list(:paragraph, 3, component: component)
              dummy_resource.link_resources([related_paragraph], "included_paragraphs")
              related_paragraph2.link_resources([dummy_resource], "included_paragraphs")

              expect(subject).to match_array([related_paragraph, related_paragraph2])
            end
          end
        end
      end
    end
  end
end
