# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::Admin::UpdateParagraphScopeEvent do
  let(:resource) { create :paragraph, title: "My super paragraph" }
  let(:resource_title) { translated(resource.title) }
  let(:event_name) { "decidim.events.enhanced_textwork.paragraph_update_scope" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("The #{resource_title} paragraph scope has been updated")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("An admin has updated the scope of your paragraph \"#{resource_title}\", check it out in this page:")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you are the author of the paragraph.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("The <a href=\"#{resource_path}\">#{resource_title}</a> paragraph scope has been updated by an admin.")
    end
  end
end
