# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe UpdateParagraph do
      let(:form_klass) { ParagraphForm }

      let(:component) { create(:paragraph_component, :with_extra_hashtags, suggested_hashtags: suggested_hashtags.join(" ")) }
      let(:organization) { component.organization }
      let(:form) do
        form_klass.from_params(
          form_params
        ).with_context(
          current_organization: organization,
          current_participatory_space: component.participatory_space,
          current_component: component
        )
      end

      let!(:paragraph) { create :paragraph, component: component, users: [author] }
      let(:author) { create(:user, organization: organization) }

      let(:user_group) do
        create(:user_group, :verified, organization: organization, users: [author])
      end

      let(:has_address) { false }
      let(:address) { nil }
      let(:latitude) { 40.1234 }
      let(:longitude) { 2.1234 }
      let(:suggested_hashtags) { [] }
      let(:attachment_params) { nil }
      let(:uploaded_photos) { [] }
      let(:current_photos) { [] }
      let(:current_files) { [] }
      let(:uploaded_files) { [] }
      let(:errors) { double.as_null_object }

      describe "call" do
        let(:title) { "A reasonable paragraph title" }
        let(:body) { "A reasonable paragraph body" }
        let(:form_params) do
          {
            title: title,
            body: body,
            address: address,
            has_address: has_address,
            user_group_id: user_group.try(:id),
            suggested_hashtags: suggested_hashtags,
            attachment: attachment_params,
            photos: current_photos,
            add_photos: uploaded_photos,
            documents: current_files,
            add_documents: uploaded_files,
            errors: errors
          }
        end

        let(:command) do
          described_class.new(form, author, paragraph)
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

        describe "when the paragraph is not editable by the user" do
          before do
            expect(paragraph).to receive(:editable_by?).and_return(false)
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

        context "when the author changinng the author to one that has reached the paragraph limit" do
          let!(:other_paragraph) { create :paragraph, component: component, users: [author], user_groups: [user_group] }
          let(:component) { create(:paragraph_component, :with_paragraph_limit) }

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        describe "when the form is valid" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "updates the paragraph" do
            command.call
            paragraph.reload
            expect(paragraph.title).to be_kind_of(Hash)
            expect(paragraph.title["en"]).to eq title
            expect(paragraph.body).to be_kind_of(Hash)
            expect(paragraph.body["en"]).to match(/^#{body}/)
          end

          context "with an author" do
            let(:user_group) { nil }

            it "sets the author" do
              command.call
              paragraph = Decidim::EnhancedTextwork::Paragraph.last

              expect(paragraph).to be_authored_by(author)
              expect(paragraph.identities.include?(user_group)).to be false
            end
          end

          context "with a user group" do
            it "sets the user group" do
              command.call
              paragraph = Decidim::EnhancedTextwork::Paragraph.last

              expect(paragraph).to be_authored_by(author)
              expect(paragraph.identities).to include(user_group)
            end
          end

          context "with extra hashtags" do
            let(:suggested_hashtags) { %w(Hashtag1 Hashtag2) }

            it "saves the extra hashtags" do
              command.call
              paragraph = Decidim::EnhancedTextwork::Paragraph.last
              expect(paragraph.body["en"]).to include("_Hashtag1")
              expect(paragraph.body["en"]).to include("_Hashtag2")
            end
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
            let(:uploaded_files) do
              [
                Decidim::Dev.test_file("Exampledocument.pdf", "application/pdf")
              ]
            end
            let(:uploaded_photos) do
              [
                Decidim::Dev.test_file("city.jpeg", "image/jpeg")
              ]
            end

            it "creates multiple atachments for the paragraph" do
              expect { command.call }.to change(Decidim::Attachment, :count).by(2)
              last_attachment = Decidim::Attachment.last
              expect(last_attachment.attached_to).to eq(paragraph)
            end

            context "with previous attachments" do
              let!(:file) { create(:attachment, :with_pdf, attached_to: paragraph) }
              let!(:photo) { create(:attachment, :with_image, attached_to: paragraph) }
              let(:current_files) { [file] }
              let(:current_photos) { [photo] }

              it "does not remove older attachments" do
                expect { command.call }.to change(Decidim::Attachment, :count).from(2).to(4)
              end
            end
          end

          context "when attachments are allowed and file is invalid" do
            let(:component) { create(:paragraph_component, :with_attachments_allowed) }
            let(:uploaded_files) do
              [
                Decidim::Dev.test_file("city.jpeg", "image/jpeg"),
                Decidim::Dev.test_file("verify_user_groups.csv", "text/csv")
              ]
            end

            it "does not create atachments for the paragraph" do
              expect { command.call }.to change(Decidim::Attachment, :count).by(0)
            end

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end
          end

          context "when documents and gallery are allowed" do
            let(:component) { create(:paragraph_component, :with_attachments_allowed) }
            let(:uploaded_photos) { [Decidim::Dev.test_file("city.jpeg", "image/jpeg")] }
            let(:uploaded_files) do
              [
                Decidim::Dev.test_file("Exampledocument.pdf", "application/pdf")
              ]
            end

            it "Create gallery and documents for the paragraph" do
              expect { command.call }.to change(Decidim::Attachment, :count).by(2)
            end
          end

          context "when gallery are allowed" do
            let(:component) { create(:paragraph_component, :with_attachments_allowed) }
            let(:uploaded_photos) { [Decidim::Dev.test_file("city.jpeg", "image/jpeg")] }

            it "creates an image attachment for the paragraph" do
              expect { command.call }.to change(Decidim::Attachment, :count).by(1)
              last_paragraph = Decidim::EnhancedTextwork::Paragraph.last
              last_attachment = Decidim::Attachment.last
              expect(last_attachment.attached_to).to eq(last_paragraph)
            end
          end
        end
      end
    end
  end
end
