# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::EvaluatingParagraphEvent do
  let(:resource) { create :paragraph, title: "My super paragraph" }
  let(:event_name) { "decidim.events.enhanced_textwork.paragraph_evaluating" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("A paragraph you're following is being evaluated")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("The paragraph \"#{translated(resource.title)}\" is currently being evaluated. You can check for an answer in this page:")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you are following \"#{translated(resource.title)}\". You can unfollow it from the previous link.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("The <a href=\"#{resource_path}\">#{translated(resource.title)}</a> paragraph is being evaluated")
    end
  end
end
