# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Textwork collection protection", type: :request do
  let(:document) { create(:textwork_document, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:user) { create(:user, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:heading) { editor.add(kind: "heading", body: "Chapter") }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees.") }
  let(:routes) { Decidim::EngineRouter.admin_proxy(document.component) }
  let(:public_routes) { Decidim::EngineRouter.main_proxy(document.component) }

  before do
    host! document.organization.host
    sign_in admin
  end

  def suggestion(status: "pending")
    block.suggestions.create!(component: document.component, author: user, block_version: block.current_version,
                              body: { en: "Trees and benches." }, changeset: { original: block.original, replace: "Trees and benches." },
                              status:, answer: { en: status == "rejected" ? "Historical decision" : "" })
  end

  it "retains preparation versions and structure history before publication" do
    editor.update(block, body: "Trees and shade.", expected_version: 1)
    editor.move(block, position: 1)
    expect(block.block_versions.pluck(:body)).to eq(["More trees.", "Trees and shade."])
    expect(document.document_revisions.pluck(:kind)).to include("block_added", "block_moved")
    expect { block.current_version.update!(body: "Overwrite") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "rejects all service text and structure edits after publication without adding history" do
    document.publish!
    operations = [
      -> { editor.add(kind: "paragraph", body: "New text") },
      -> { editor.update(block, body: "Replacement", expected_version: 1) },
      -> { editor.move(block, position: 1) },
      -> { editor.remove(block) }
    ]
    operations.each { |operation| expect(&operation).to raise_error(Decidim::ActionForbidden) }
    expect(block.reload.original).to eq("More trees.")
    expect(block.block_versions.count).to eq(1)
    expect(document.document_revisions.count).to eq(2)
    expect(block).not_to be_removed
  end

  it "rejects direct admin edits to text, structure, original title and description" do
    document.publish!
    post routes.add_block_path, params: { body: "Injected", kind: "paragraph", depth: 1 }
    expect(response).to have_http_status(:redirect)
    patch routes.update_block_path(block_id: block.id), params: { body: "Injected", expected_version: 1 }
    expect(response).to have_http_status(:redirect)
    patch routes.move_block_path(block_id: block.id), params: { position: 1 }
    expect(response).to have_http_status(:redirect)
    delete routes.remove_block_path(block_id: block.id)
    expect(response).to have_http_status(:redirect)
    patch routes.update_document_path, params: { title: { en: "Injected title" } }
    expect(response).to have_http_status(:redirect)
    patch routes.update_document_path, params: { description: { en: "Injected description" } }
    expect(response).to have_http_status(:redirect)
    expect(document.reload.original(:title)).to eq("Community plan")
    expect(document.original(:description)).to eq("A participatory document")
    expect(document.blocks.active.ordered.pluck(:id)).to eq([heading.id, block.id])
    expect(block.reload.original).to eq("More trees.")
    expect(block.block_versions.count).to eq(1)
  end

  it "allows withdrawal and corrections when no stored participation exists" do
    document.publish!
    patch routes.publish_document_path
    expect(document.reload).not_to be_published
    patch routes.update_document_path, params: { title: { en: "Corrected title" }, description: { en: "Corrected description" } }
    patch routes.update_block_path(block_id: block.id), params: { body: "Trees and shade.", expected_version: 1 }
    expect(document.reload.original(:title)).to eq("Corrected title")
    expect(document.original(:description)).to eq("Corrected description")
    expect(block.reload.original).to eq("Trees and shade.")
    expect(block.current_version_number).to eq(2)
  end

  %w(pending withdrawn accepted rejected).each do |status|
    it "counts #{status} suggestions as stored participation" do
      suggestion(status:)
      expect(document).to be_participation
      expect(document).not_to be_original_editable
      document.publish!
      patch routes.publish_document_path
      expect(document.reload).to be_published
    end
  end

  it "counts moderated suggestions and feedback on removed blocks" do
    record = suggestion(status: "withdrawn")
    Decidim::Moderation.create!(reportable: record, participatory_space: document.participatory_space, hidden_at: Time.current)
    block.update!(removed_at: Time.current)
    expect(document).to be_participation
    expect { editor.update(heading, body: "Changed chapter", expected_version: 1) }.to raise_error(Decidim::ActionForbidden)
    expect(document.blocks.active).not_to include(block)
  end

  it "counts hidden and soft-deleted comments even when public counters are zero" do
    document.publish!
    comment = create(:comment, commentable: block, author: user)
    Decidim::Moderation.create!(reportable: comment, participatory_space: document.participatory_space, hidden_at: Time.current)
    comment.update!(deleted_at: Time.current)
    expect(block.reload.comments_count).to eq(0)
    expect(document).to be_participation
    patch routes.publish_document_path
    expect(document.reload).to be_published
  end

  it "uses stored likes rather than a permanent marker after an unlike" do
    document.publish!
    like = Decidim::Like.create!(resource: heading, author: user)
    expect(document).to be_participation
    patch routes.publish_document_path
    expect(document.reload).to be_published
    like.destroy!
    expect(document).not_to be_participation
    patch routes.publish_document_path
    expect(document.reload).not_to be_published
    expect(document).to be_original_editable
  end

  it "counts document likes as well as block likes" do
    Decidim::Like.create!(resource: document, author: user)
    expect(document).to be_participation
    expect(document).not_to be_original_editable
  end

  it "protects already withdrawn legacy documents with participation" do
    suggestion(status: "withdrawn")
    patch routes.update_document_path, params: { title: { en: "Changed" } }
    patch routes.update_block_path(block_id: block.id), params: { body: "Changed", expected_version: 1 }
    expect(document.reload.original(:title)).to eq("Community plan")
    expect(block.reload.original).to eq("More trees.")
    expect { editor.add(kind: "paragraph", body: "Changed") }.to raise_error(Decidim::ActionForbidden)
  end

  it "allows translation maintenance on a published original without new original versions" do
    document.organization.update!(available_locales: %w(en de))
    document.publish!
    suggestion
    patch routes.update_document_path, params: { title: { de: "Ein Plan" }, description: { de: "Beschreibung" } }
    expect(response).to have_http_status(:redirect)
    patch routes.update_block_path(block_id: block.id), params: { expected_version: 1, translations: { de: "Mehr Bäume." }, reviewed: ["de"] }
    expect(response).to have_http_status(:redirect)
    expect(document.reload.title).to include("en" => "Community plan", "de" => "Ein Plan")
    expect(document.description).to include("en" => "A participatory document", "de" => "Beschreibung")
    expect(block.reload.body).to include("en" => "More trees.", "de" => "Mehr Bäume.")
    expect(block.block_versions.count).to eq(1)
    expect(document.document_revisions.count).to eq(2)
    get routes.edit_block_path(block_id: block.id)
    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css("textarea[name=body]")["readonly"]).to be_present
    expect(html.at_css('textarea[name="translations[de]"]')["readonly"]).to be_nil
  end

  it "rolls back translations sent together with a forbidden original change" do
    document.organization.update!(available_locales: %w(en de))
    document.publish!
    patch routes.update_document_path, params: { title: { de: "Should roll back" }, description: { en: "Forbidden" } }
    patch routes.update_block_path(block_id: block.id), params: { body: "Forbidden", expected_version: 1, translations: { de: "Should roll back" } }
    expect(document.reload.title).not_to have_key("de")
    expect(block.reload.body).not_to have_key("de")
    expect(block.original).to eq("More trees.")
  end

  it "trashes with participation, preserves feedback, and restores the same protected document" do
    document.publish!
    record = suggestion
    comment = create(:comment, commentable: record, author: user)
    likes = [document, heading, record].map { |resource| Decidim::Like.create!(resource:, author: user).id }
    follow = Decidim::Follow.create!(followable: document, user:)
    delete routes.trash_document_path
    expect(document.reload).to be_deleted
    expect(document.searchable_resources).to be_empty
    expect(Decidim::Like.where(id: likes).count).to eq(3)
    expect(Decidim::Follow.exists?(follow.id)).to be(true)
    expect(Decidim::Comments::Comment.exists?(comment.id)).to be(true)
    expect(record.reload.status).to eq("pending")
    get public_routes.document_path(document)
    expect(response).to have_http_status(:not_found)
    patch routes.restore_document_path
    expect(document.reload).not_to be_deleted
    expect(document).to be_published
    expect(document).not_to be_original_editable
    expect(document.searchable_resources).to be_present
    patch routes.publish_document_path
    expect(document.reload).to be_published
    expect(Decidim::Like.where(id: likes).count).to eq(3)
  end

  it "hides edit, decision and unpublish controls while retaining the trash action" do
    document.publish!
    record = suggestion
    get routes.textwork_path
    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    expect(html.css('a[href*="/suggestions/"], form[action$="/publish"], form[action$="/move"], form[action$="/blocks"]')).to be_empty
    expect(html.css("form").any? { |form| form["action"] == routes.trash_document_path && form.at_css('input[value="delete"]') }).to be(true)
    expect(response.body).not_to include(routes.review_suggestion_path(suggestion_id: record.id))
    expect(html.at_css('input[name="title[en]"]')["readonly"]).to be_present
  end

  it "hides trashed discussion through Core comment URLs and search, then restores it" do
    document.publish!
    record = suggestion
    comment = create(:comment, commentable: block, author: user, body: { en: "Paragraph discussion" })
    reply = create(:comment, commentable: comment, root_commentable: block, author: user)
    proposal_comment = create(:comment, commentable: record, author: user, body: { en: "Suggestion discussion" })
    comment_routes = Decidim::Comments::Engine.routes.url_helpers
    delete routes.trash_document_path
    sign_out admin
    [block, record, comment].each do |resource|
      get comment_routes.comments_path(format: :js), params: { commentable_gid: resource.to_signed_global_id.to_s }, headers: { "X-Requested-With" => "XMLHttpRequest" }
      expect(response).to have_http_status(:redirect)
      expect(response.body).not_to include("Paragraph discussion", "Suggestion discussion")
    end
    [comment, reply, proposal_comment].each do |item|
      expect(item.reload).not_to be_visible
      expect(item.searchable_resources).to be_empty
    end
    sign_in admin
    patch routes.restore_document_path
    [comment, reply, proposal_comment].each do |item|
      expect(item.reload).to be_visible
      expect(item.searchable_resources).to be_present
    end
    get comment_routes.comments_path(format: :js), params: { commentable_gid: block.to_signed_global_id.to_s }, headers: { "X-Requested-With" => "XMLHttpRequest" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Paragraph discussion")
  end

  it "keeps Core comment behaviour for roots outside Textwork" do
    comment = Decidim::Comments::Comment.new(commentable: document.participatory_space, root_commentable: document.participatory_space)
    expect(comment.commentable?).to be(true)
    expect(comment.visible?).to be_nil
    action = Decidim::PermissionAction.new(scope: :public, action: :read, subject: :comment)
    expect(Decidim::Comments::Permissions.new(nil, action, commentable: comment).permissions).to be_allowed
  end

  it "defaults evaluation off and rejects acceptance/rejection even when the switch is enabled" do
    expect(document.component.settings.evaluation_enabled?).to be(false)
    document.publish!
    record = suggestion
    [false, true].each do |enabled|
      document.component.update!(settings: { evaluation_enabled: enabled })
      get routes.review_suggestion_path(suggestion_id: record.id)
      expect(response).to have_http_status(:redirect)
      %w(accepted rejected).each do |decision|
        patch routes.decide_suggestion_path(suggestion_id: record.id), params: { decision:, answer: "Reviewed", body: record.original, expected_version: 1 }
        expect(response).to have_http_status(:redirect)
        expect { editor.decide(record, decision:, answer: "Reviewed", body: record.original, expected_version: 1) }.to raise_error(Decidim::ActionForbidden)
        expect(record.reload.status).to eq("pending")
      end
    end
    expect(block.block_versions.count).to eq(1)
  end

  it "blocks history index, individual versions and document history for participants and admins" do
    document.publish!
    [user, admin].each do |reader|
      sign_in reader
      [public_routes.history_document_path(document), public_routes.block_versions_path(block), public_routes.block_version_path(block, 1)].each do |path|
        get path
        expect(response).to have_http_status(:forbidden)
      end
      get public_routes.document_path(document)
      expect(response.body).not_to include(public_routes.history_document_path(document))
      get public_routes.panel_document_path(document, block: block.id)
      expect(response.body).not_to include(public_routes.block_versions_path(block))
    end
    expect(block.block_versions.count).to eq(1)
    expect(document.document_revisions.count).to eq(2)
  end
end
