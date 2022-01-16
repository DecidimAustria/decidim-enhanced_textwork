# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::Admin::ParagraphNoteCreatedEvent do
  let(:resource) { create :paragraph, title: ::Faker::Lorem.characters(number: 25) }
  let(:resource_title) { translated(resource.title) }
  let(:event_name) { "decidim.events.enhanced_textwork.admin.paragraph_note_created" }
  let(:component) { resource.component }
  let(:admin_paragraph_info_path) { "/admin/participatory_processes/#{participatory_space.slug}/components/#{component.id}/manage/paragraphs/#{resource.id}" }
  let(:admin_paragraph_info_url) { "http://#{organization.host}/admin/participatory_processes/#{participatory_space.slug}/components/#{component.id}/manage/paragraphs/#{resource.id}" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("Someone left a note on paragraph #{resource_title}.")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq(%(Someone has left a note on the paragraph "#{resource_title}". Check it out at <a href="#{admin_paragraph_info_url}">the admin panel</a>))
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you can valuate the paragraph.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include(%(Someone has left a note on the paragraph <a href="#{resource_path}">#{resource_title}</a>. Check it out at <a href="#{admin_paragraph_info_path}">the admin panel</a>))
    end
  end
end
