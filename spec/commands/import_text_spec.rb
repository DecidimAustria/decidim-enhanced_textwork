# frozen_string_literal: true

require "spec_helper"

RSpec.describe Decidim::EnhancedTextwork::Admin::ImportText do
  let(:component) { create(:proposal_component, settings: { participatory_texts_enabled: true, enhanced_textwork_enabled: true }) }
  let(:user) { create(:user, :admin, organization: component.organization) }
  let(:content) { "<h1>A document</h1><p>First <strong>paragraph</strong>.</p><p>Second paragraph.</p>" }
  let(:form) do
    Decidim::EnhancedTextwork::Admin::ImportForm.from_params(title_en: "Document", content:).with_context(
      current_component: component, current_user: user, current_organization: component.organization
    )
  end

  it "creates ordered, unpublished core paragraphs and document metadata" do
    described_class.call(form)
    paragraphs = Decidim::Proposals::Proposal.where(component:).order(:position)
    expect(paragraphs.map(&:participatory_text_level)).to eq(%w(section article article))
    expect(paragraphs.map(&:published_at)).to all(be_nil)
    expect(paragraphs.second.body["en"]).to include("<strong>paragraph</strong>")
    expect(Decidim::Proposals::ParticipatoryText.find_by(component:).title["en"]).to eq("Document")
  end

  it "refuses a second import rather than merging or replacing an existing document" do
    described_class.call(form)
    expect { described_class.call(form) }.not_to change(Decidim::Proposals::Proposal, :count)
    expect(form.errors[:content]).not_to be_empty
  end

  context "with only empty editor markup" do
    let(:content) { "<p><br></p>" }

    it "does not leave metadata or paragraphs behind" do
      described_class.call(form)
      expect(form.errors[:content]).not_to be_empty
      expect(Decidim::Proposals::ParticipatoryText.where(component:)).to be_empty
      expect(Decidim::Proposals::Proposal.where(component:)).to be_empty
    end
  end
end
