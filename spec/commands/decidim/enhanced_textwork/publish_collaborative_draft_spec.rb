# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe PublishCollaborativeDraft do
      let(:component) { create(:paragraph_component) }
      let(:state) { :open }
      let!(:collaborative_draft) { create(:collaborative_draft, component: component, state: state) }
      let!(:attachment) { Decidim::Attachment.create(attachment_params) }
      let(:attachment_params) do
        {
          title: "My attachment",
          file: Decidim::Dev.test_file("city.jpeg", "image/jpeg"),
          attached_to: collaborative_draft
        }
      end
      let(:current_user) { collaborative_draft.creator_author }
      let(:command) { described_class.new(collaborative_draft, current_user) }

      describe "call" do
        context "when the user is not a coauthor" do
          let(:current_user) { create(:user, organization: component.organization) }

          it "broadcasts invalid" do
            expect(collaborative_draft.authored_by?(current_user)).to eq(false)
            expect { command.call }.to broadcast(:invalid)
          end
        end

        context "when the resource is withdrawn" do
          let(:state) { :withdrawn }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        context "when the resource is published" do
          let(:state) { :published }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        context "when everything is ok" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new paragraph" do
            expect { command.call }
              .to change(Decidim::EnhancedTextwork::Paragraph, :count)
              .by(1)
          end

          it "transfers the attributes correctly" do
            command.call
            paragraph = Decidim::EnhancedTextwork::Paragraph.last

            expect(paragraph.category).to eq(collaborative_draft.category)
            expect(paragraph.scope).to eq(collaborative_draft.scope)
            expect(paragraph.address).to eq(collaborative_draft.address)
            expect(paragraph.attachments).to eq(collaborative_draft.attachments)
          end
        end
      end
    end
  end
end
