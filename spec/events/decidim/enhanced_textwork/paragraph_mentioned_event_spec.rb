# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::ParagraphMentionedEvent do
  include_context "when a simple event"

  let(:event_name) { "decidim.events.enhanced_textwork.paragraph_mentioned" }
  let(:organization) { create :organization }
  let(:author) { create :user, organization: organization }

  let(:source_paragraph) { create :paragraph, component: create(:paragraph_component, organization: organization), title: "Paragraph A" }
  let(:mentioned_paragraph) { create :paragraph, component: create(:paragraph_component, organization: organization), title: "Paragraph B" }
  let(:resource) { source_paragraph }
  let(:extra) do
    {
      mentioned_paragraph_id: mentioned_paragraph.id
    }
  end

  it_behaves_like "a simple event"

  describe "types" do
    subject { described_class }

    it "supports notifications" do
      expect(subject.types).to include :notification
    end

    it "supports emails" do
      expect(subject.types).to include :email
    end
  end

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("Your paragraph \"#{translated(mentioned_paragraph.title)}\" has been mentioned")
    end
  end

  context "with content" do
    let(:content) do
      "Your paragraph \"#{translated(mentioned_paragraph.title)}\" has been mentioned " \
        "<a href=\"#{resource_url}\">in this space</a> in the comments."
    end

    describe "email_intro" do
      let(:resource_url) { resource_locator(source_paragraph).url }

      it "is generated correctly" do
        expect(subject.email_intro).to eq(content)
      end
    end

    describe "notification_title" do
      let(:resource_url) { resource_locator(source_paragraph).path }

      it "is generated correctly" do
        expect(subject.notification_title).to include(content)
      end
    end
  end
end
