# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe DestroyParagraph do
      describe "call" do
        let(:component) { create(:paragraph_component) }
        let(:organization) { component.organization }
        let(:current_user) { create(:user, organization: organization) }
        let(:other_user) { create(:user, organization: organization) }
        let!(:paragraph) { create :paragraph, component: component, users: [current_user] }
        let(:paragraph_draft) { create(:paragraph, :draft, component: component, users: [current_user]) }
        let!(:paragraph_draft_other) { create :paragraph, component: component, users: [other_user] }

        it "broadcasts ok" do
          expect { described_class.call(paragraph_draft, current_user) }.to broadcast(:ok)
          expect { paragraph_draft.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "broadcasts invalid when the paragraph is not a draft" do
          expect { described_class.call(paragraph, current_user) }.to broadcast(:invalid)
        end

        it "broadcasts invalid when the paragraph_draft is from another author" do
          expect { described_class.call(paragraph_draft_other, current_user) }.to broadcast(:invalid)
        end
      end
    end
  end
end
