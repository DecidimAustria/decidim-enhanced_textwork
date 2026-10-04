# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin Textwork tools", type: :request do
  let(:component) { create(:proposal_component, settings: { participatory_texts_enabled: true, enhanced_textwork_enabled: true }) }
  let(:organization) { component.organization }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:routes) { Decidim::EngineRouter.admin_proxy(component) }

  before do
    host! organization.host
    sign_in user
  end

  it "renders the editor and the document export link" do
    get routes.textwork_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Textwork tools", "Download Word report")
  end

  it "links the tools from the core participatory-text preview" do
    get routes.participatory_texts_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(routes.textwork_path)
    component.update!(settings: component.settings.to_h.merge(enhanced_textwork_enabled: false))
    get routes.participatory_texts_path(locale: :en)
    expect(response.body).not_to include(routes.textwork_path)
  end

  it "accepts the editor form and redirects to the core draft review" do
    post routes.import_textwork_path(locale: :en), params: { import: { title_en: "My document", content: "<p>Our first paragraph.</p>" } }
    expect(response).to redirect_to(routes.participatory_texts_path)
    expect(Decidim::Proposals::Proposal.where(component:).drafts.count).to eq(1)
    expect(Decidim::Proposals::ParticipatoryText.find_by(component:).title["en"]).to eq("My document")
  end

  it "exports the component as a Word document" do
    get routes.export_textwork_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
  end

  it "deletes an unpublished paragraph, but refuses published paragraphs" do
    draft = create(:proposal, :unpublished, component:)
    published = create(:proposal, component:)
    delete routes.textwork_draft_path(draft, locale: :en)
    expect(response).to have_http_status(:redirect)
    expect(Decidim::Proposals::Proposal.exists?(draft.id)).to be(false)
    delete routes.textwork_draft_path(published, locale: :en)
    expect(response).to have_http_status(:not_found)
    expect(Decidim::Proposals::Proposal.exists?(published.id)).to be(true)
  end

  it "refuses to delete another component's draft" do
    draft = create(:proposal, :unpublished)
    delete routes.textwork_draft_path(draft, locale: :en)
    expect(response).to have_http_status(:not_found)
    expect(Decidim::Proposals::Proposal.exists?(draft.id)).to be(true)
  end

  context "as a participant" do
    let(:user) { create(:user, :confirmed, organization:) }

    it "does not allow exporting the document" do
      get routes.export_textwork_path(locale: :en)
      expect(response).not_to have_http_status(:ok)
      expect(response.media_type).not_to eq("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    end
  end
end
