# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::EnhancedTextwork::DocumentExport do
  let(:component) { create(:proposal_component, settings: { participatory_texts_enabled: true, enhanced_textwork_enabled: true }) }
  let(:user) { create(:user, :admin, organization: component.organization) }

  def exported_text
    data = described_class.new(component, user, :en).export
    text = nil
    Zip::File.open_buffer(data) do |zip|
      xml = Nokogiri::XML(zip.read("word/document.xml")) { |config| config.strict }
      text = xml.xpath("//w:t", "w" => Decidim::EnhancedTextwork::WordDocument::WORD_NS).map(&:text).join("\n")
    end
    text
  end

  it "exports an empty component as a valid document" do
    expect(exported_text).to include(component.name["en"])
  end

  it "uses paragraph order and excludes unpublished content" do
    create(:proposal, component:, title: { en: "Later" }, body: { en: "Later body" }, participatory_text_level: "article", position: 2)
    create(:proposal, component:, title: { en: "Earlier" }, body: { en: "Earlier body" }, participatory_text_level: "article", position: 1)
    create(:proposal, :unpublished, component:, title: { en: "Private draft" })
    text = exported_text
    expect(text.index("Earlier")).to be < text.index("Later")
    expect(text).not_to include("Private draft")
  end

  it "includes threaded comments while excluding deleted comments" do
    paragraph = create(:proposal, component:, participatory_text_level: "article")
    comment = create(:comment, commentable: paragraph, body: { en: "A root comment" })
    create(:comment, commentable: comment, root_commentable: paragraph, body: { en: "A reply" })
    create(:comment, commentable: paragraph, body: { en: "Deleted content" }, deleted_at: Time.current)
    text = exported_text
    expect(text).to include("A root comment", "A reply")
    expect(text).not_to include("Deleted content")
  end

  it "excludes moderated content and replies beneath a moderated comment" do
    paragraph = create(:proposal, component:, participatory_text_level: "article")
    create(:proposal, :hidden, component:, body: { en: "Hidden paragraph" }, participatory_text_level: "article")
    comment = create(:comment, :moderated, commentable: paragraph, body: { en: "Hidden root" })
    create(:comment, commentable: comment, root_commentable: paragraph, body: { en: "Reply to hidden root" })
    expect(exported_text).not_to include("Hidden paragraph", "Hidden root", "Reply to hidden root")
  end

  it "includes published amendment bodies and their discussion" do
    component.update!(settings: component.settings.to_h.merge(amendments_enabled: true))
    paragraph = create(:proposal, component:, participatory_text_level: "article")
    emendation = create(:proposal, component:, title: { en: "Suggested revision" }, body: { en: "A revised paragraph" })
    create(:amendment, amendable: paragraph, emendation:)
    create(:comment, commentable: emendation, body: { en: "Comment on amendment" })
    expect(exported_text).to include("Suggested revision", "A revised paragraph", "Comment on amendment")
  end
end
