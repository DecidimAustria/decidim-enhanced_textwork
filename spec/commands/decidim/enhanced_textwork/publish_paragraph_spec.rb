# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe PublishParagraph do
      describe "call" do
        let(:component) { create(:paragraph_component) }
        let(:organization) { component.organization }
        let!(:current_user) { create(:user, organization: organization) }
        let(:follower) { create(:user, organization: organization) }
        let(:paragraph_draft) { create(:paragraph, :draft, component: component, users: [current_user]) }
        let!(:follow) { create :follow, followable: current_user, user: follower }

        it "broadcasts ok" do
          expect { described_class.call(paragraph_draft, current_user) }.to broadcast(:ok)
        end

        it "scores on the paragraphs badge" do
          expect { described_class.call(paragraph_draft, current_user) }.to change {
            Decidim::Gamification.status_for(current_user, :paragraphs).score
          }.by(1)
        end

        it "broadcasts invalid when the paragraph is from another author" do
          expect { described_class.call(paragraph_draft, follower) }.to broadcast(:invalid)
        end

        describe "events" do
          subject do
            described_class.new(paragraph_draft, current_user)
          end

          it "notifies the paragraph is published" do
            other_follower = create(:user, organization: organization)
            create(:follow, followable: component.participatory_space, user: follower)
            create(:follow, followable: component.participatory_space, user: other_follower)

            allow(Decidim::EventsManager).to receive(:publish)
              .with(hash_including(event: "decidim.events.gamification.badge_earned"))

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.enhanced_textwork.paragraph_published",
                event_class: Decidim::EnhancedTextwork::PublishParagraphEvent,
                resource: kind_of(Decidim::EnhancedTextwork::Paragraph),
                followers: [follower]
              )

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.enhanced_textwork.paragraph_published",
                event_class: Decidim::EnhancedTextwork::PublishParagraphEvent,
                resource: kind_of(Decidim::EnhancedTextwork::Paragraph),
                followers: [other_follower],
                extra: {
                  participatory_space: true
                }
              )

            subject.call
          end
        end
      end
    end
  end
end
