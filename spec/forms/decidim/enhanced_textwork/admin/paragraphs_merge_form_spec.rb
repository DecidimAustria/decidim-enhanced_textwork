# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe ParagraphsMergeForm do
        subject { form }

        let(:paragraphs) { create_list(:paragraph, 3, component: component) }
        let(:component) { create(:paragraph_component) }
        let(:target_component) { create(:paragraph_component, participatory_space: component.participatory_space) }
        let(:params) do
          {
            target_component_id: [target_component.try(:id).to_s],
            paragraph_ids: paragraphs.map(&:id)
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_component: component,
            current_participatory_space: component.participatory_space
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "without a target component" do
          let(:target_component) { nil }

          it { is_expected.to be_invalid }
        end

        context "when not enough paragraphs" do
          let(:paragraphs) { create_list(:paragraph, 1, component: component) }

          it { is_expected.to be_invalid }
        end

        context "when given a target component from another space" do
          let(:target_component) { create(:paragraph_component) }

          it { is_expected.to be_invalid }
        end

        context "when merging to the same component" do
          let(:target_component) { component }
          let(:paragraphs) { create_list(:paragraph, 3, :official, component: component) }

          context "when the paragraph is not official" do
            let(:paragraphs) { create_list(:paragraph, 3, component: component) }

            it { is_expected.to be_invalid }
          end

          context "when a paragraph has a vote" do
            before do
              create(:paragraph_vote, paragraph: paragraphs.sample)
            end

            it { is_expected.to be_invalid }
          end

          context "when a paragraph has an endorsement" do
            before do
              create(:endorsement, resource: paragraphs.sample, author: create(:user, organization: component.participatory_space.organization))
            end

            it { is_expected.to be_invalid }
          end
        end
      end
    end
  end
end
