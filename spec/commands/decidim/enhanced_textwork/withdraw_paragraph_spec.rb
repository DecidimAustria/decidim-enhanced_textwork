# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe WithdrawParagraph do
      let(:paragraph) { create(:paragraph) }

      before do
        paragraph.save!
      end

      describe "when current user IS the author of the paragraph" do
        let(:current_user) { paragraph.creator_author }
        let(:command) { described_class.new(paragraph, current_user) }

        context "and the paragraph has no supports" do
          it "withdraws the paragraph" do
            expect do
              expect { command.call }.to broadcast(:ok)
            end.to change { Decidim::EnhancedTextwork::Paragraph.count }.by(0)
            expect(paragraph.state).to eq("withdrawn")
          end
        end

        context "and the paragraph HAS some supports" do
          before do
            paragraph.votes.create!(author: current_user)
          end

          it "is not able to withdraw the paragraph" do
            expect do
              expect { command.call }.to broadcast(:has_supports)
            end.to change { Decidim::EnhancedTextwork::Paragraph.count }.by(0)
            expect(paragraph.state).not_to eq("withdrawn")
          end
        end
      end
    end
  end
end
