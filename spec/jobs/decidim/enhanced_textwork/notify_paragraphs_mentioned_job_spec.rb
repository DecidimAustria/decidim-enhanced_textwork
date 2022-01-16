# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe NotifyParagraphsMentionedJob do
      subject { described_class }

      include_context "when creating a comment"

      let(:comment) { create(:comment, commentable: commentable) }
      let(:paragraph_component) { create(:paragraph_component, organization: organization) }
      let(:paragraph_metadata) { Decidim::ContentParsers::ParagraphParser::Metadata.new([]) }
      let(:linked_paragraph) { create(:paragraph, component: paragraph_component) }
      let(:linked_paragraph_official) { create(:paragraph, :official, component: paragraph_component) }

      describe "integration" do
        it "is correctly scheduled" do
          ActiveJob::Base.queue_adapter = :test
          paragraph_metadata[:linked_paragraphs] << linked_paragraph
          paragraph_metadata[:linked_paragraphs] << linked_paragraph_official
          comment = create(:comment)

          expect do
            Decidim::Comments::CommentCreation.publish(comment, paragraph: paragraph_metadata)
          end.to have_enqueued_job.with(comment.id, paragraph_metadata.linked_paragraphs)
        end
      end

      describe "with mentioned paragraphs" do
        let(:linked_paragraphs) do
          [
            linked_paragraph.id,
            linked_paragraph_official.id
          ]
        end

        let!(:space_admin) do
          create(:process_admin, participatory_process: linked_paragraph_official.component.participatory_space)
        end

        it "notifies the author about it" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.enhanced_textwork.paragraph_mentioned",
              event_class: Decidim::EnhancedTextwork::ParagraphMentionedEvent,
              resource: commentable,
              affected_users: [linked_paragraph.creator_author],
              extra: {
                comment_id: comment.id,
                mentioned_paragraph_id: linked_paragraph.id
              }
            )

          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.enhanced_textwork.paragraph_mentioned",
              event_class: Decidim::EnhancedTextwork::ParagraphMentionedEvent,
              resource: commentable,
              affected_users: [space_admin],
              extra: {
                comment_id: comment.id,
                mentioned_paragraph_id: linked_paragraph_official.id
              }
            )

          subject.perform_now(comment.id, linked_paragraphs)
        end
      end
    end
  end
end
