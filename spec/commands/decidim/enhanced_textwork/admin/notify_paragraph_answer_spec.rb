# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe NotifyParagraphAnswer do
        subject { command.call }

        let(:command) { described_class.new(paragraph, initial_state) }
        let(:paragraph) { create(:paragraph, :accepted) }
        let(:initial_state) { nil }
        let(:current_user) { create(:user, :admin) }
        let(:follow) { create(:follow, followable: paragraph, user: follower) }
        let(:follower) { create(:user, organization: paragraph.organization) }

        before do
          follow

          # give paragraph author initial points to avoid unwanted events during tests
          Decidim::Gamification.increment_score(paragraph.creator_author, :accepted_paragraphs)
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "notifies the paragraph followers" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.enhanced_textwork.paragraph_accepted",
              event_class: Decidim::EnhancedTextwork::AcceptedParagraphEvent,
              resource: paragraph,
              affected_users: match_array([paragraph.creator_author]),
              followers: match_array([follower])
            )

          subject
        end

        it "increments the accepted paragraphs counter" do
          expect { subject }.to change { Gamification.status_for(paragraph.creator_author, :accepted_paragraphs).score }.by(1)
        end

        context "when the paragraph is rejected after being accepted" do
          let(:paragraph) { create(:paragraph, :rejected) }
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "notifies the paragraph followers" do
            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.enhanced_textwork.paragraph_rejected",
                event_class: Decidim::EnhancedTextwork::RejectedParagraphEvent,
                resource: paragraph,
                affected_users: match_array([paragraph.creator_author]),
                followers: match_array([follower])
              )

            subject
          end

          it "decrements the accepted paragraphs counter" do
            expect { subject }.to change { Gamification.status_for(paragraph.coauthorships.first.author, :accepted_paragraphs).score }.by(-1)
          end
        end

        context "when the paragraph published state has not changed" do
          let(:initial_state) { "accepted" }

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "doesn't notify the paragraph followers" do
            expect(Decidim::EventsManager)
              .not_to receive(:publish)

            subject
          end

          it "doesn't modify the accepted paragraphs counter" do
            expect { subject }.not_to(change { Gamification.status_for(current_user, :accepted_paragraphs).score })
          end
        end
      end
    end
  end
end
