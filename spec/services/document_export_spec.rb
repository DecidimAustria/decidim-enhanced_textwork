# frozen_string_literal: true

require "spec_helper"
RSpec.describe Decidim::EnhancedTextwork::DocumentExport do
  let!(:section) { create(:textwork_section) }
  let(:component) { section.component }
  let(:user) { create(:user, :admin, organization: component.organization) }
  def exported_text
    data = described_class.new(component, user, :en).export
    result = nil
    Zip::File.open_buffer(data) { |zip| result = Nokogiri::XML(zip.read("word/document.xml")).text }
    result
  end
  it "exports paragraphs, amendments and threaded comments" do
    amendment = create(:textwork_amendment, section:)
    root = create(:comment, commentable: section, body: { en: "A root comment" })
    create(:comment, commentable: root, root_commentable: section, body: { en: "A reply" })
    create(:comment, commentable: amendment, body: { en: "Amendment discussion" })
    expect(exported_text).to include("More trees", "A root comment", "A reply", "Amendment discussion")
  end
  it "excludes deleted and moderated content" do
    create(:comment, commentable: section, body: { en: "Deleted content" }, deleted_at: Time.current)
    amendment = create(:textwork_amendment, section:, body: { en: "Hidden amendment" })
    create(:moderation, reportable: amendment, hidden_at: Time.current)
    expect(exported_text).not_to include("Deleted content", "Hidden amendment")
  end
  it "does not export an unpublished document's paragraphs" do
    section.document.update!(published_at: nil)
    expect(exported_text).not_to include("More trees")
  end
end
