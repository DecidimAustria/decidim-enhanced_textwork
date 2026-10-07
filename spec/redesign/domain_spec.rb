# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Textwork redesign domain" do
  let(:document) { create(:textwork_document, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:author) { create(:user, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:heading) { editor.add(body: "A greener district", kind: "heading") }
  let!(:block) { editor.add(body: "More trees.", kind: "paragraph") }

  def suggest(body = "More trees and benches.")
    document.publish!
    result = nil
    Decidim::EnhancedTextwork::SaveSuggestion.call(block, author, body:, expected_version: block.current_version_number) do
      on(:ok) { |record| result = record }
    end
    expect(result).to be_present
    result
  end

  it "numbers active blocks and retains stable IDs when moved" do
    second = editor.add(body: "Safe roads.", kind: "paragraph")
    expect(block.number).to eq("1.1")
    expect(second.number).to eq("1.2")
    editor.move(second, position: 2)
    expect(block.number).to eq("1.2")
    expect(second.number).to eq("1.1")
    expect(second.block_versions.count).to eq(1)
    expect(second.versions.count).to eq(1)
  end

  it "preserves manual translations as outdated and changes original exactly once" do
    block.update!(body: { en: block.original, de: "Mehr Bäume", machine_translations: { es: "Más árboles" } })
    versions = block.versions.count
    editor.update(block, body: "Trees and shade.", expected_version: 1)
    expect(block.reload.body).to eq("en" => "Trees and shade.")
    expect(block.outdated_translations.dig("body", "de")).to eq("Mehr Bäume")
    expect(block.block_versions.count).to eq(2)
    expect(block.versions.count).to eq(versions + 1)
    expect { editor.update(block, body: "Lost edit", expected_version: 1) }.to raise_error(Decidim::EnhancedTextwork::EditDocument::Conflict)
    expect(block.reload.original).to eq("Trees and shade.")
  end

  it "accepts a reviewed stale suggestion and records the adjusted result" do
    # Preserve regression coverage of the retained legacy decision algorithm.
    # Its collection policy is tested without stubs in collection_lock_spec.
    allow(document).to receive(:original_editable?).and_return(true)
    document.component.update!(settings: { evaluation_enabled: true })
    suggestion = suggest
    editor.update(block, body: "More trees, shade and drinking water.", expected_version: 1)
    expect(suggestion.outdated?).to be(true)
    editor.decide(suggestion, decision: "accepted", answer: "Reviewed", body: "Trees, benches and water.", expected_version: 2)
    expect(suggestion.reload.status).to eq("accepted")
    expect(block.reload.current_version.adjusted).to be(true)
    expect(block.current_version.suggestion).to eq(suggestion)
    expect(suggestion.changeset["original"]).to eq("More trees.")
  end

  it "soft removes and rejects open suggestions, preserving contributions" do
    allow(document).to receive(:original_editable?).and_return(true)
    suggestion = suggest
    old_id = block.id
    editor.remove(block)
    expect(block.reload.removed?).to be(true)
    expect(document.blocks.active).not_to include(block)
    expect(Decidim::EnhancedTextwork::Block.find(old_id)).to eq(block)
    expect(suggestion.reload.status).to eq("rejected")
    expect(suggestion.original(:answer)).to eq(I18n.t("decidim.textwork.removed_reason"))
    expect(block.block_versions.count).to eq(1)
    expect(document.document_revisions.last.kind).to eq("block_removed")
  end

  it "cannot edit after first feedback, even if counters return to zero" do
    suggestion = suggest
    suggestion.update!(feedback_received_at: Time.current, likes_count: 0, comments_count: 0)
    expect(suggestion.editable_by?(author)).to be(false)
    expect(suggestion.withdrawable_by?(author)).to be(true)
  end

  it "rejects unchanged normalized suggestions while preserving meaningful newlines" do
    suggestion = block.suggestions.build(component: document.component, author:, block_version: block.current_version,
                                         changeset: { original: block.original, replace: " More   trees. " }, body: { en: " More   trees. " })
    expect(suggestion).not_to be_valid
    expect(Decidim::EnhancedTextwork::Suggestion.normalize("- a\n- b")).not_to eq(Decidim::EnhancedTextwork::Suggestion.normalize("- a - b"))
  end

  it "retains chapter likes and locks preparation once feedback exists" do
    Decidim::Like.create!(resource: heading, author:)
    expect { editor.update(block, body: "Many trees.", expected_version: 1) }.to raise_error(Decidim::ActionForbidden)
    expect(heading.reload.likes_count).to eq(1)
    expect(heading.liked_by?(author)).to be(true)
    document.publish!
    expect(block.likeable?).to be(true)
    expect(heading.likeable?).to be(false)
  end

  it "protects admin changes against participants" do
    expect { Decidim::EnhancedTextwork::EditDocument.new(document, author) }.to raise_error(Decidim::ActionForbidden)
  end

  it "sanitizes rendered Markdown and preserves whole lists on import" do
    html = Decidim::EnhancedTextwork::Markdown.render("**Good** <script>alert(1)</script> ![image](https://example.org/image.png)")
    expect(html).to include("<strong>Good</strong>")
    expect(html).not_to match(/<script|<img/)
    blocks = Decidim::EnhancedTextwork::Markdown.from_html("<h1>Chapter</h1><ul><li>A</li><li>B</li></ul>")
    expect(blocks.size).to eq(2)
    expect(blocks.last[:body]).to eq("- A\n- B")
  end
end
