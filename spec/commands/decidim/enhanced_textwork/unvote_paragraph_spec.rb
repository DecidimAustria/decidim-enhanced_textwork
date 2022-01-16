# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe UnvoteParagraph do
      describe "call" do
        let(:paragraph) { create(:paragraph) }
        let(:current_user) { create(:user, organization: paragraph.component.organization) }
        let!(:paragraph_vote) { create(:paragraph_vote, author: current_user, paragraph: paragraph) }
        let(:command) { described_class.new(paragraph, current_user) }

        it "broadcasts ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "deletes the paragraph vote for that user" do
          expect do
            command.call
          end.to change(ParagraphVote, :count).by(-1)
        end

        it "decrements the right score for that user" do
          Decidim::Gamification.set_score(current_user, :paragraph_votes, 10)
          command.call
          expect(Decidim::Gamification.status_for(current_user, :paragraph_votes).score).to eq(9)
        end
      end
    end
  end
end
