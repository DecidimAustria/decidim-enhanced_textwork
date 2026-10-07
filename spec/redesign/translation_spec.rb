# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::EnhancedTextwork::TranslationRequest do
  let(:document) { create(:textwork_document, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees.") }

  before do
    document.organization.update!(available_locales: %w(en de), enable_machine_translations: true)
    allow(Decidim).to receive(:machine_translation_service_klass).and_return(Class.new)
  end

  it "queues once per source and locale, only when read" do
    expect(described_class.count).to eq(0)
    first = described_class.request(block, :body, :de)
    second = described_class.request(block, :body, :de)
    expect(second.id).to eq(first.id)
    expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count { |job| job[:job] == Decidim::EnhancedTextwork::TranslationJob }).to eq(1)
  end

  it "saves a provider response without creating a content or PaperTrail version" do
    document.publish!
    request = described_class.request(block, :body, :de)
    versions = block.versions.count
    Decidim::MachineTranslationSaveJob.perform_now(request, :payload, "de", "Mehr Bäume.")
    expect(block.reload.body.dig("machine_translations", "de")).to eq("Mehr Bäume.")
    expect(block.block_versions.count).to eq(1)
    expect(block.versions.count).to eq(versions)
    expect(request.reload.status).to eq("completed")
  end

  it "rejects a late response for an old original" do
    request = described_class.request(block, :body, :de)
    editor.update(block, body: "New benches.", expected_version: 1)
    Decidim::MachineTranslationSaveJob.perform_now(request, :payload, "de", "Mehr Bäume.")
    expect(block.reload.body).to eq("en" => "New benches.")
    expect(request.reload.status).to eq("obsolete")
    expect(described_class.request(block, :body, :de).id).not_to eq(request.id)
  end

  it "does not overwrite a reviewed manual translation" do
    request = described_class.request(block, :body, :de)
    block.update!(body: block.body.merge("de" => "Von Hand geprüft."))
    Decidim::MachineTranslationSaveJob.perform_now(request, :payload, "de", "Mehr Bäume.")
    expect(block.reload.reading(:body, :de)).to eq("Von Hand geprüft.")
  end

  it "reuses the completed translation when the exact original text returns" do
    request = described_class.request(block, :body, :de)
    Decidim::MachineTranslationSaveJob.perform_now(request, :payload, "de", "Mehr Bäume.")
    editor.update(block, body: "New benches.", expected_version: 1)
    editor.update(block, body: "More trees.", expected_version: 2)
    described_class.request(block, :body, :de)
    expect(block.reload.reading(:body, :de)).to eq("Mehr Bäume.")
    expect(described_class.count).to eq(1)
  end
end
