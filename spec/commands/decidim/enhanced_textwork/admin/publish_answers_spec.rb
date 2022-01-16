# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe PublishAnswers do
        subject { command.call }

        let(:command) { described_class.new(component, user, paragraph_ids) }
        let(:paragraph_ids) { paragraphs.map(&:id) }
        let(:paragraphs) { create_list(:paragraph, 5, :accepted_not_published, component: component) }
        let(:component) { create(:paragraph_component) }
        let(:user) { create(:user, :admin) }

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the answers" do
          expect { subject }.to change { paragraphs.map { |paragraph| paragraph.reload.published_state? }.uniq }.to([true])
        end

        it "changes the paragraphs published state" do
          expect { subject }.to change { paragraphs.map { |paragraph| paragraph.reload.state }.uniq }.from([nil]).to(["accepted"])
        end

        it "traces the action", versioning: true do
          paragraphs.each do |paragraph|
            expect(Decidim.traceability)
              .to receive(:perform_action!)
              .with("publish_answer", paragraph, user)
              .and_call_original
          end

          expect { subject }.to change(Decidim::ActionLog, :count)
          action_log = Decidim::ActionLog.last
          expect(action_log.version).to be_present
          expect(action_log.version.event).to eq "update"
        end

        it "notifies the answers" do
          paragraphs.each do |paragraph|
            expect(NotifyParagraphAnswer)
              .to receive(:call)
              .with(paragraph, nil)
          end

          subject
        end

        context "when paragraph ids belong to other component" do
          let(:paragraphs) { create_list(:paragraph, 5, :accepted) }

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't publish the answers" do
            expect { subject }.not_to(change { paragraphs.map { |paragraph| paragraph.reload.published_state? }.uniq })
          end

          it "doesn't trace the action" do
            expect(Decidim.traceability)
              .not_to receive(:perform_action!)

            subject
          end

          it "doesn't notify the answers" do
            expect(NotifyParagraphAnswer).not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
