# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe AnswerParagraph do
        subject { command.call }

        let(:command) { described_class.new(form, paragraph) }
        let(:paragraph) { create(:paragraph) }
        let(:current_user) { create(:user, :admin) }
        let(:form) do
          ParagraphAnswerForm.from_params(form_params).with_context(
            current_user: current_user,
            current_component: paragraph.component,
            current_organization: paragraph.component.organization
          )
        end

        let(:form_params) do
          {
            internal_state: "rejected",
            answer: { en: "Foo" },
            cost: 2000,
            cost_report: { en: "Cost report" },
            execution_period: { en: "Execution period" }
          }
        end

        it "broadcasts ok" do
          expect { subject }.to broadcast(:ok)
        end

        it "publish the paragraph answer" do
          expect { subject }.to change { paragraph.reload.published_state? }.to(true)
        end

        it "changes the paragraph state" do
          expect { subject }.to change { paragraph.reload.state }.to("rejected")
        end

        it "traces the action", versioning: true do
          expect(Decidim.traceability)
            .to receive(:perform_action!)
            .with("answer", paragraph, form.current_user)
            .and_call_original

          expect { subject }.to change(Decidim::ActionLog, :count)
          action_log = Decidim::ActionLog.last
          expect(action_log.version).to be_present
          expect(action_log.version.event).to eq "update"
        end

        it "notifies the paragraph answer" do
          expect(NotifyParagraphAnswer)
            .to receive(:call)
            .with(paragraph, nil)

          subject
        end

        context "when the form is not valid" do
          before do
            expect(form).to receive(:invalid?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { subject }.to broadcast(:invalid)
          end

          it "doesn't change the paragraph state" do
            expect { subject }.not_to(change { paragraph.reload.state })
          end
        end

        context "when applying over an already answered paragraph" do
          let(:paragraph) { create(:paragraph, :accepted) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the paragraph state" do
            expect { subject }.to change { paragraph.reload.state }.to("rejected")
          end

          it "notifies the paragraph new answer" do
            expect(NotifyParagraphAnswer)
              .to receive(:call)
              .with(paragraph, "accepted")

            subject
          end
        end

        context "when paragraph answer should not be published immediately" do
          let(:paragraph) { create(:paragraph, component: component) }
          let(:component) { create(:paragraph_component, :without_publish_answers_immediately) }

          it "broadcasts ok" do
            expect { subject }.to broadcast(:ok)
          end

          it "changes the paragraph internal state" do
            expect { subject }.to change { paragraph.reload.internal_state }.to("rejected")
          end

          it "doesn't publish the paragraph answer" do
            expect { subject }.not_to change { paragraph.reload.published_state? }.from(false)
          end

          it "doesn't notify the paragraph answer" do
            expect(NotifyParagraphAnswer)
              .not_to receive(:call)

            subject
          end
        end
      end
    end
  end
end
