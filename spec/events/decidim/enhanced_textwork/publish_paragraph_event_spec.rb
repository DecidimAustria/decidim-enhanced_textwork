# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe PublishParagraphEvent do
      let(:resource) { create :paragraph, title: "A nice paragraph" }
      let(:resource_title) { translated(resource.title) }
      let(:event_name) { "decidim.events.enhanced_textwork.paragraph_published" }

      include_context "when a simple event"
      it_behaves_like "a simple event"

      describe "resource_text" do
        it "returns the paragraph body" do
          expect(subject.resource_text).to eq(resource.body)
        end
      end

      describe "email_subject" do
        it "is generated correctly" do
          expect(subject.email_subject).to eq("New paragraph \"#{resource_title}\" by @#{author.nickname}")
        end
      end

      describe "email_intro" do
        it "is generated correctly" do
          expect(subject.email_intro)
            .to eq("#{author.name} @#{author.nickname}, who you are following, has published a new paragraph called \"#{resource_title}\". Check it out and contribute:")
        end
      end

      describe "email_outro" do
        it "is generated correctly" do
          expect(subject.email_outro)
            .to eq("You have received this notification because you are following @#{author.nickname}. You can stop receiving notifications following the previous link.")
        end
      end

      describe "notification_title" do
        it "is generated correctly" do
          expect(subject.notification_title)
            .to include("The <a href=\"#{resource_path}\">#{resource_title}</a> paragraph was published by ")

          expect(subject.notification_title)
            .to include("<a href=\"/profiles/#{author.nickname}\">#{author.name} @#{author.nickname}</a>.")
        end
      end

      context "when the target are the participatory space followers" do
        let(:event_name) { "decidim.events.enhanced_textwork.paragraph_published_for_space" }
        let(:extra) { { participatory_space: true } }

        include_context "when a simple event"
        it_behaves_like "a simple event"

        describe "email_subject" do
          it "is generated correctly" do
            expect(subject.email_subject).to eq("New paragraph \"#{resource_title}\" added to #{participatory_space_title}")
          end
        end

        describe "email_intro" do
          it "is generated correctly" do
            expect(subject.email_intro).to eq("The paragraph \"A nice paragraph\" has been added to \"#{participatory_space_title}\" that you are following.")
          end
        end

        describe "email_outro" do
          it "is generated correctly" do
            expect(subject.email_outro)
              .to include("You have received this notification because you are following \"#{participatory_space_title}\"")
          end
        end

        describe "notification_title" do
          it "is generated correctly" do
            expect(subject.notification_title)
              .to eq("The paragraph <a href=\"#{resource_path}\">A nice paragraph</a> has been added to #{participatory_space_title}")
          end
        end
      end
    end
  end
end
