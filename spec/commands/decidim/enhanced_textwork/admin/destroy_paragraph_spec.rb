# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe DestroyParagraph do
        describe "call" do
          let(:current_component) do
            create(
              :paragraph_component,
              participatory_space: create(:participatory_process)
            )
          end
          # let(:command) { described_class.new(current_component) }
          # let(:component) { create(:paragraph_component) }
          let(:organization) { current_component.organization }
          let(:current_user) { create(:user, organization: organization) }
          # let(:other_user) { create(:user, organization: organization) }
          let!(:paragraph) { create :paragraph, component: current_component, users: [current_user] }
          let(:paragraph_draft) { create(:paragraph, :draft, component: current_component) }

          it "broadcasts ok and deletes the draft" do
            expect { described_class.new(paragraph_draft).call }.to broadcast(:ok)
            expect { paragraph_draft.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end

          it "broadcasts invalid when the paragraph is not a draft" do
            expect { described_class.new(paragraph).call }.to broadcast(:invalid)
          end
        end
      end
    end
  end
end
