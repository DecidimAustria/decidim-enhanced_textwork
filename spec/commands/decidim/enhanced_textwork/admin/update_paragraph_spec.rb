# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::Admin::UpdateParagraph do
  let(:form_klass) { Decidim::EnhancedTextwork::Admin::ParagraphForm }

  let(:component) { create(:paragraph_component) }
  let(:organization) { component.organization }
  let(:user) { create :user, :admin, :confirmed, organization: organization }
  let(:form) do
    form_klass.from_params(
      form_params
    ).with_context(
      current_organization: organization,
      current_participatory_space: component.participatory_space,
      current_user: user,
      current_component: component
    )
  end

  let!(:paragraph) { create :paragraph, :official, component: component }

  let(:has_address) { false }
  let(:address) { nil }
  let(:attachment_params) { nil }
  let(:uploaded_photos) { [] }
  let(:current_photos) { [] }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  describe "call" do
    let(:form_params) do
      {
        title: { en: "A reasonable paragraph title" },
        body: { en: "A reasonable paragraph body" },
        address: address,
        has_address: has_address,
        attachment: attachment_params,
        photos: current_photos,
        add_photos: uploaded_photos
      }
    end

    let(:command) do
      described_class.new(form, paragraph)
    end

    describe "when the form is not valid" do
      before do
        expect(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "doesn't update the paragraph" do
        expect do
          command.call
        end.not_to change(paragraph, :title)
      end
    end

    describe "when the form is valid" do
      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "updates the paragraph" do
        expect do
          command.call
        end.to change(paragraph, :title)
      end

      it "traces the update", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(paragraph, user, a_kind_of(Hash))
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)

        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
        expect(action_log.version.event).to eq "update"
      end

      context "when geocoding is enabled" do
        let(:component) { create(:paragraph_component, :with_geocoding_enabled) }

        context "when the has address checkbox is checked" do
          let(:has_address) { true }

          context "when the address is present" do
            let(:address) { "Some address" }

            before do
              stub_geocoding(address, [latitude, longitude])
            end

            it "sets the latitude and longitude" do
              command.call
              paragraph = Decidim::EnhancedTextwork::Paragraph.last

              expect(paragraph.latitude).to eq(latitude)
              expect(paragraph.longitude).to eq(longitude)
            end
          end
        end
      end

      context "when attachments are allowed" do
        let(:component) { create(:paragraph_component, :with_attachments_allowed) }
        let(:attachment_params) do
          {
            title: "My attachment",
            file: Decidim::Dev.test_file("city.jpeg", "image/jpeg")
          }
        end

        it "creates an atachment for the paragraph" do
          expect { command.call }.to change(Decidim::Attachment, :count).by(1)
          last_paragraph = Decidim::EnhancedTextwork::Paragraph.last
          last_attachment = Decidim::Attachment.last
          expect(last_attachment.attached_to).to eq(last_paragraph)
        end

        context "when attachment is left blank" do
          let(:attachment_params) do
            {
              title: ""
            }
          end

          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end
        end
      end

      it_behaves_like "admin manages resource gallery" do
        let(:component) { create(:paragraph_component, :with_attachments_allowed) }
        let!(:resource) { paragraph }
        let(:command) { described_class.new(form, resource) }
        let(:resource_class) { Decidim::EnhancedTextwork::Paragraph }
        let(:attachment_params) { { title: "" } }
      end
    end
  end
end
