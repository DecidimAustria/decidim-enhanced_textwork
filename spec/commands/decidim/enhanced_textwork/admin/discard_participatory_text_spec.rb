# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe DiscardParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :paragraph_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:paragraphs) do
            create_list(:paragraph, 3, :draft, component: current_component)
          end
          let(:command) { described_class.new(current_component) }

          describe "when discarding" do
            it "removes all drafts" do
              expect { command.call }.to broadcast(:ok)
              paragraphs = Decidim::EnhancedTextwork::Paragraph.drafts.where(component: current_component)
              expect(paragraphs).to be_empty
            end
          end
        end
      end
    end
  end
end
