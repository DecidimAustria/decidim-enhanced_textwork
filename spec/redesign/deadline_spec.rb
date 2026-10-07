# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Textwork collection deadlines", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:document) { create(:textwork_document, published_at: nil) }
  let(:component) { document.component }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:user) { create(:user, :confirmed, organization: document.organization) }
  let(:other) { create(:user, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees.") }
  let!(:step) { create(:participatory_process_step, :active, participatory_process: component.participatory_space) }
  let(:routes) { Decidim::EngineRouter.main_proxy(component) }
  let(:core) { Decidim::Core::Engine.routes.url_helpers }
  let(:comments) { Decidim::Comments::Engine.routes.url_helpers }
  let(:xhr) { { "X-Requested-With" => "XMLHttpRequest" } }

  before do
    document.organization.update!(time_zone: "Europe/Vienna")
    document.publish!
    host! document.organization.host
    sign_in user
  end

  def expire!
    step.update!(end_date: Date.new(2026, 10, 6))
    travel_to Time.utc(2026, 10, 6, 22, 0, 0)
    sign_out user
    sign_in user
    component.participatory_space.reload
  end

  it "uses the organization day including the whole end date regardless of ambient zone and reopens on extension" do
    step.update!(end_date: Date.new(2026, 10, 6))
    travel_to Time.utc(2026, 10, 6, 21, 59, 59) do
      Time.use_zone("Pacific/Honolulu") { expect(Decidim::EnhancedTextwork::Participation.open?(component, :likes)).to be(true) }
    end
    travel_to Time.utc(2026, 10, 6, 22, 0, 0) do
      Time.use_zone("Pacific/Honolulu") { expect(Decidim::EnhancedTextwork::Participation.open?(component, :likes)).to be(false) }
      step.update!(end_date: Date.new(2026, 10, 7))
      component.participatory_space.reload
      expect(Decidim::EnhancedTextwork::Participation.open?(component, :likes)).to be(true)
    end
  end

  it "blocks module and Core likes/unlikes and every suggestion write after expiry" do
    post routes.block_suggestions_path(block), params: { body: "Trees and benches.", expected_version: 1 }
    suggestion = block.suggestions.last!
    Decidim::Like.create!(resource: block, author: user)
    expire!
    [[:post, core.likes_path(format: :js), { resource_id: block.to_gid.to_s }],
     [:delete, core.like_path(block.to_gid.to_param, format: :js), {}]].each do |method, path, values|
      public_send(method, path, params: values, headers: xhr)
      expect(response).to have_http_status(:redirect)
    end
    expect(block.reload.likes_count).to eq(1)
    post routes.interaction_path(resource_type: :block, resource_id: block.id, kind: :like)
    expect(response).to have_http_status(:forbidden)
    post routes.block_suggestions_path(block), params: { body: "Trees and parks.", expected_version: 1 }
    expect(response).to have_http_status(:forbidden)
    patch routes.block_suggestion_path(block, suggestion), params: { body: "Trees and parks.", expected_version: 1 }
    expect(response).to have_http_status(:forbidden)
    patch routes.withdraw_suggestion_path(suggestion)
    expect(response).to have_http_status(:forbidden)
    expect(suggestion.reload.status).to eq("pending")
  end

  it "blocks Core comment create, reply, edit and vote even for administrators, retaining own deletion and document follow" do
    own = create(:comment, commentable: block, author: user, body: { en: "Keep this discussion" })
    foreign = create(:comment, commentable: block, author: other, body: { en: "Another opinion" })
    expire!
    [user, admin].each do |actor|
      sign_in actor
      [block, own].each do |root|
        post comments.comments_path(format: :js), params: { comment: { commentable_gid: root.to_sgid.to_s, body: "Closed write", alignment: 0 } }, headers: xhr
        expect(response).to have_http_status(:redirect)
      end
      post comments.comment_votes_path(foreign, format: :js), params: { weight: 1 }, headers: xhr
      expect(response).to have_http_status(:redirect)
    end
    sign_in user
    patch comments.comment_path(own, format: :js), params: { comment: { body: "Edited after deadline" } }, headers: xhr
    expect(response).to have_http_status(:redirect)
    expect(own.reload.body).to eq("en" => "Keep this discussion")
    delete comments.comment_path(own, format: :js), headers: xhr
    expect(response).to have_http_status(:ok)
    expect(own.reload).to be_deleted
    post core.follow_path(format: :js), params: { follow: { followable_gid: document.to_sgid.to_s, button_classes: "button" } }, headers: xhr
    expect(response).to have_http_status(:ok)
    expect(Decidim::Follow.exists?(followable: document, user:)).to be(true)
    delete core.follow_path(format: :js), params: { follow: { followable_gid: document.to_sgid.to_s, button_classes: "button" } }, headers: xhr
    expect(response).to have_http_status(:ok)
    expect(Decidim::Follow.exists?(followable: document, user:)).to be(false)
  end

  it "honours step and global flags, while missing deadlines leave an open collection" do
    step.update!(end_date: nil)
    expect(Decidim::EnhancedTextwork::Participation.open?(component, :likes)).to be(true)
    component.update!(step_settings: { step.id.to_s => { likes_enabled: false } })
    expect(Decidim::EnhancedTextwork::Participation.open?(component, :likes)).to be(false)
    component.update!(step_settings: { step.id.to_s => { likes_enabled: true } }, settings: { likes_enabled: false })
    expect(Decidim::EnhancedTextwork::Participation.open?(component, :likes)).to be(false)
    component.update!(settings: { comments_enabled: false })
    expect(block.accepts_new_comments?).to be(false)
  end
end
