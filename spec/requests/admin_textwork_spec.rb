# frozen_string_literal: true

require "spec_helper"
RSpec.describe "Independent Textwork administration", type: :request do
  let(:component) { create(:textwork_component, :published) }
  let(:organization) { component.organization }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:routes) { Decidim::EngineRouter.admin_proxy(component) }
  before do
    host! organization.host
    sign_in user
  end
  it "renders the editor without Proposals administration" do
    get routes.textwork_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Textwork tools", "Download Word report")
  end
  it "imports and publishes a document" do
    post routes.import_textwork_path(locale: :en), params: { import: { title_en: "My document", content: "<p>Our paragraph.</p>" } }
    expect(response).to have_http_status(:redirect)
    document = Decidim::EnhancedTextwork::Document.find_by!(component:)
    expect(document.published?).to be(false)
    patch routes.publish_textwork_path(locale: :en)
    expect(document.reload.published?).to be(true)
    expect(document.document_versions.count).to eq(1)
  end
  it "exports a Word report" do
    get routes.export_textwork_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
  end
  it "imports an uploaded Markdown file without editor content" do
    Tempfile.create(["plan", ".md"]) do |file|
      file.write("# Community plan\n\nMore trees.")
      file.flush
      upload = Rack::Test::UploadedFile.new(file.path, "text/markdown")
      post routes.import_textwork_path(locale: :en), params: { import: { title_en: "My document", document: upload } }
      expect(response).to have_http_status(:redirect)
      document = Decidim::EnhancedTextwork::Document.find_by!(component:)
      expect(document.sections.count).to eq(2)
      expect(document.sections.last.body["en"]).to include("More trees")
    end
  end
  it "lets the administrator of this process decide an amendment" do
    sign_out user
    process_admin = create(:user, :confirmed, :admin_terms_accepted, organization:)
    create(:participatory_process_user_role, user: process_admin, participatory_process: component.participatory_space, role: :admin)
    sign_in process_admin
    section = create(:textwork_section, document: create(:textwork_document, component:))
    amendment = create(:textwork_amendment, section:)
    patch routes.decide_amendment_path(amendment, locale: :en), params: { state: "accepted", decision_reason: "Agreed" }
    expect(response).to have_http_status(:redirect)
    expect(amendment.reload.state).to eq("accepted")
    expect(section.reload.current_revision).to eq(amendment.result_revision)
  end
  it "does not let an amendment author decide it" do
    section = create(:textwork_section, document: create(:textwork_document, component:))
    amendment = create(:textwork_amendment, section:)
    sign_out user
    sign_in amendment.author
    patch routes.decide_amendment_path(amendment, locale: :en), params: { state: "accepted" }
    expect(response).not_to have_http_status(:success)
    expect(amendment.reload.state).to eq("pending")
  end
  it "does not let ordinary participants publish" do
    sign_out user
    sign_in create(:user, :confirmed, organization:)
    patch routes.publish_textwork_path(locale: :en)
    expect(response).not_to have_http_status(:success)
    expect(Decidim::EnhancedTextwork::Document.where(component:)).to be_empty
  end
  it "preserves published sections when deletion is requested" do
    document = create(:textwork_document, component:)
    section = create(:textwork_section, document:)
    delete routes.section_path(section, locale: :en)
    expect(response).to have_http_status(:conflict)
    expect(section.reload).to be_present
  end
  it "creates a revision when an administrator edits a published paragraph" do
    section = create(:textwork_section, document: create(:textwork_document, component:))
    original = section.current_revision
    patch routes.section_path(section, locale: :en), params: { base_revision_id: original.id, title: "1", body: "Changed text" }
    expect(response).to have_http_status(:redirect)
    expect(section.reload.current_revision.number).to eq(2)
    expect(original.reload.body["en"]).to include("More trees")
  end
end
