# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Redesigned Textwork", type: :request do
  let(:document) { create(:textwork_document, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:user) { create(:user, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:heading) { editor.add(kind: "heading", body: "Chapter") }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees.") }
  let(:routes) { Decidim::EngineRouter.main_proxy(document.component) }

  before do
    host! document.organization.host
    document.publish!
  end

  it "renders the document and independently loads comment and suggestion panels" do
    get routes.document_path(document)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("More trees.", "data-controller=\"textwork\"")
    get routes.panel_document_path(document, block: block.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-decidim-comments")
    get routes.panel_document_path(document, block: block.id, mode: "suggestions")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("decidim.textwork.suggestions.empty"))
  end

  it "uses Core likes for paragraphs and refuses heading likes" do
    sign_in user
    path = routes.interaction_path(resource_type: :block, resource_id: block.id, kind: :like)
    post path
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to include("liked" => true, "likes" => 1)
    post path
    expect(block.likes.count).to eq(1)
    delete path
    expect(response).to have_http_status(:ok)
    expect(block.likes.count).to eq(0)
    post routes.interaction_path(resource_type: :block, resource_id: heading.id, kind: :like)
    expect(response).to have_http_status(:forbidden)
  end

  it "rejects chapter follows and cross-component resource IDs" do
    sign_in user
    post routes.interaction_path(resource_type: :block, resource_id: heading.id, kind: :follow)
    expect(response).to have_http_status(:forbidden)
    expect(Decidim::Follow.exists?(followable: heading, user:)).to be(false)
    other = create(:textwork_document, published_at: nil)
    other_admin = create(:user, :admin, organization: other.organization)
    other_heading = Decidim::EnhancedTextwork::EditDocument.new(other, other_admin).add(kind: "heading", body: "Other")
    post routes.interaction_path(resource_type: :block, resource_id: other_heading.id, kind: :like)
    expect(response).to have_http_status(:not_found)
  end

  it "creates and withdraws a suggestion and enforces the phase lock" do
    sign_in user
    post routes.block_suggestions_path(block), params: { body: "Trees and benches.", expected_version: 1 }
    expect(response).to have_http_status(:ok)
    suggestion = block.suggestions.last!
    patch routes.withdraw_suggestion_path(suggestion)
    expect(response).to have_http_status(:ok)
    expect(suggestion.reload.status).to eq("withdrawn")
    component = document.component
    component.update!(default_step_settings: { suggestions_blocked: true })
    post routes.block_suggestions_path(block), params: { body: "Trees and benches.", expected_version: 1 }
    expect(response).to have_http_status(:forbidden)
  end

  it "shows a notice for removed blocks and hides moderated suggestion bodies" do
    sign_in user
    post routes.block_suggestions_path(block), params: { body: "Private hidden draft.", expected_version: 1 }
    suggestion = block.suggestions.last!
    Decidim::Moderation.create!(reportable: suggestion, participatory_space: document.participatory_space, hidden_at: Time.current)
    get routes.panel_document_path(document, block: block.id, suggestion: suggestion.id)
    expect(response.body).to include("unavailable")
    expect(response.body).not_to include("Private hidden draft")
    expect(block.pending_suggestions_count).to eq(0)
    # Fixture representing a block removed before the collection-only upgrade.
    block.update!(removed_at: Time.current)
    get routes.panel_document_path(document, block: block.id)
    expect(response.body).to include("paragraph was removed")
  end

  it "retains preparation versions while blocking public history routes" do
    document.unpublish!
    editor.update(block, body: "Many more trees.", expected_version: 1)
    document.publish!
    get routes.block_versions_path(block)
    expect(response).to have_http_status(:forbidden)
    get routes.block_version_path(block, 2)
    expect(response).to have_http_status(:forbidden)
    expect(block.block_versions.count).to eq(2)
  end

  it "blocks admin review and decisions in the collection phase" do
    sign_in user
    post routes.block_suggestions_path(block), params: { body: "Trees and benches.", expected_version: 1 }
    suggestion = block.suggestions.last!
    admin_routes = Decidim::EngineRouter.admin_proxy(document.component)
    patch admin_routes.decide_suggestion_path(suggestion_id: suggestion.id), params: { decision: "accepted", body: suggestion.original, expected_version: 1 }
    expect(suggestion.reload.status).to eq("pending")
    sign_in admin
    get admin_routes.review_suggestion_path(suggestion_id: suggestion.id)
    expect(response).to have_http_status(:redirect)
    patch admin_routes.decide_suggestion_path(suggestion_id: suggestion.id), params: { decision: "accepted", body: suggestion.original, expected_version: 1 }
    expect(response).to have_http_status(:redirect)
    expect(suggestion.reload.status).to eq("pending")
  end

  it "imports editor headings and a complete list, publishes and preserves the document in trash" do
    empty_component = create(:textwork_component, :published, participatory_space: document.participatory_space)
    admin_routes = Decidim::EngineRouter.admin_proxy(empty_component)
    public_routes = Decidim::EngineRouter.main_proxy(empty_component)
    sign_in admin
    get admin_routes.textwork_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(/<link[^>]+href="[^"]*decidim_enhanced_textwork_admin[^"]*\.css"/)
    post admin_routes.create_document_path, params: {
      import: { title: { en: "A greener neighbourhood" }, description: { en: "Read and participate" }, locale: "en",
                content: "<h1>Greener streets</h1><p>More trees.</p><ul><li>Benches</li><li>Water</li></ul><h1>Together</h1><p>Meet monthly.</p>" }
    }
    imported = Decidim::EnhancedTextwork::Document.find_by!(component: empty_component)
    expect(imported.blocks.ordered.pluck(:kind)).to eq(%w(heading paragraph paragraph heading paragraph))
    expect(imported.blocks.ordered.third.original).to eq("- Benches\n- Water")
    expect(imported.document_revisions.pluck(:number, :kind)).to eq([[1, "import"]])
    expect(imported).not_to be_published
    patch admin_routes.publish_document_path
    expect(imported.reload).to be_published
    expect(imported.searchable_resources).to be_present
    get public_routes.document_path(imported)
    expect(response).to have_http_status(:ok)
    delete admin_routes.trash_document_path
    expect(imported.reload).to be_deleted
    expect(imported.searchable_resources).to be_empty
    expect(imported.blocks.count).to eq(5)
    get public_routes.document_path(imported)
    expect(response).to have_http_status(:not_found)
    patch admin_routes.restore_document_path
    expect(imported.reload).not_to be_deleted
    expect(imported.searchable_resources).to be_present
    get public_routes.document_path(imported)
    expect(response).to have_http_status(:ok)
  end

  it "retains unchanged manual translations as outdated until an admin reviews them" do
    document.unpublish!
    document.organization.update!(available_locales: %w(en de))
    block.update!(body: { en: block.original, de: "Mehr Bäume." })
    sign_in admin
    admin_routes = Decidim::EngineRouter.admin_proxy(document.component)
    patch admin_routes.update_block_path(block_id: block.id), params: {
      body: "More trees and shade.", expected_version: 1, translations: { de: "Mehr Bäume." }
    }
    expect(block.reload.body).not_to have_key("de")
    expect(block.outdated_translations.dig("body", "de")).to eq("Mehr Bäume.")
    document.publish!
    patch admin_routes.update_block_path(block_id: block.id), params: {
      body: block.original, expected_version: 2, translations: { de: "Mehr Bäume und Schatten." }, reviewed: ["de"]
    }
    expect(block.reload.body["de"]).to eq("Mehr Bäume und Schatten.")
    expect(block.current_version_number).to eq(2)
  end

  it "retains archived contributions without exposing collection history" do
    sign_in user
    post routes.block_suggestions_path(block), params: { body: "Trees and benches.", expected_version: 1 }
    create(:comment, commentable: block, author: user, body: { en: "Preserve this discussion." })
    block.update!(removed_at: Time.current)
    get routes.block_versions_path(block)
    expect(response).to have_http_status(:forbidden)
    expect(block.comments.pluck(:body)).to include("en" => "Preserve this discussion.")
    expect(block.suggestions.last!.original).to eq("Trees and benches.")
  end

  it "permanently prevents editing after a Core like is withdrawn" do
    sign_in user
    post routes.block_suggestions_path(block), params: { body: "Trees and benches.", expected_version: 1 }
    suggestion = block.suggestions.last!
    liker = create(:user, :confirmed, organization: document.organization)
    sign_in liker
    path = routes.interaction_path(resource_type: :suggestion, resource_id: suggestion.id, kind: :like)
    post path
    expect(response).to have_http_status(:ok)
    delete path
    expect(response).to have_http_status(:ok)
    sign_in user
    patch routes.block_suggestion_path(block, suggestion), params: { body: "Silently replaced.", expected_version: 1 }
    expect(response).to have_http_status(:forbidden)
    expect(suggestion.reload.original).to eq("Trees and benches.")
  end

  it "allows process administrators but refuses the same role in another process" do
    process_admin = create(:user, :confirmed, :admin_terms_accepted, organization: document.organization)
    create(:participatory_process_user_role, user: process_admin, participatory_process: document.participatory_space, role: "admin")
    sign_in process_admin
    admin_routes = Decidim::EngineRouter.admin_proxy(document.component)
    get admin_routes.textwork_path
    expect(response).to have_http_status(:ok)
    expect(Decidim::EnhancedTextwork::Access.admin?(process_admin, document.component)).to be(true)
    other_process = create(:participatory_process, organization: document.organization)
    other_component = create(:textwork_component, participatory_space: other_process)
    expect(Decidim::EnhancedTextwork::Access.admin?(process_admin, other_component)).to be(false)
    expect do
      Decidim::EnhancedTextwork::EditDocument.new(create(:textwork_document, component: other_component), process_admin)
    end.to raise_error(Decidim::ActionForbidden)
  end
end
