# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Textwork Core participation", type: :request do
  let(:document) { create(:textwork_document, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:user) { create(:user, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:heading) { editor.add(kind: "heading", body: "Chapter") }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees.") }
  let(:routes) { Decidim::Core::Engine.routes.url_helpers }
  let(:xhr) { { "X-Requested-With" => "XMLHttpRequest" } }

  before do
    document.publish!
    host! document.organization.host
    sign_in user
  end

  def suggestion(author = admin)
    block.suggestions.create!(component: document.component, author:, block_version: block.current_version,
                              body: { en: "More trees and benches." }, changeset: { original: block.original, replace: "More trees and benches." })
  end

  it "likes paragraphs and foreign suggestions through Core while rejecting headings and own suggestions" do
    foreign = suggestion
    own = suggestion(user)
    [block, foreign].each do |resource|
      post routes.likes_path(format: :js), params: { resource_id: resource.to_global_id.to_s }, headers: xhr
      expect(response).to have_http_status(:ok)
      expect(resource.reload.likes_count).to eq(1)
    end
    image = document.blocks.create!(component: document.component, kind: "image", editor_image: create(:editor_image, organization: document.organization, author: admin), position: 3)
    [document, heading, image, own].each do |resource|
      post routes.likes_path(format: :js), params: { resource_id: resource.to_global_id.to_s }, headers: xhr
      expect(response).to have_http_status(:redirect)
      expect(resource.reload.likes_count).to eq(0)
    end
  end

  it "permits withdrawal of an existing own like but never a new own like" do
    own = suggestion(user)
    Decidim::Like.create!(resource: own, author: user)
    expect(Decidim::EnhancedTextwork::Participation.like_allowed?(user, own, add: false)).to be(true)
    delete routes.like_path(own.to_gid.to_param, format: :js), headers: xhr
    expect(response).to have_http_status(:ok)
    expect(own.reload.likes_count).to eq(0)
    expect(own.feedback_received_at).to be_present
    expect(own.editable_by?(user)).to be(false)
    post routes.likes_path(format: :js), params: { resource_id: own.to_global_id.to_s }, headers: xhr
    expect(response).to have_http_status(:redirect)
  end

  it "permanently locks suggestion editing after a Core like and unlike" do
    foreign = suggestion
    sign_in admin
    liker = create(:user, :confirmed, organization: document.organization)
    Decidim::LikeResource.call(foreign, liker)
    Decidim::UnlikeResource.call(foreign, liker)
    expect(foreign.reload.feedback_received_at).to be_present
    expect(foreign.editable_by?(admin)).to be(false)
  end

  it "follows only documents through Core and preserves access after the deadline" do
    post routes.follow_path(format: :js), params: { follow: { followable_gid: document.to_sgid.to_s, button_classes: "button" } }, headers: xhr
    expect(response).to have_http_status(:ok)
    expect(Decidim::Follow.exists?(followable: document, user:)).to be(true)
    post routes.follow_path(format: :js), params: { follow: { followable_gid: heading.to_sgid.to_s, button_classes: "button" } }, headers: xhr
    expect(response).to have_http_status(:redirect)
    expect(Decidim::Follow.exists?(followable: heading, user:)).to be(false)
  end

  it "counts only pending proposals and paragraph comments and uses a fixed query budget" do
    record = suggestion
    hidden = suggestion
    withdrawn = suggestion
    withdrawn.update!(status: "withdrawn")
    Decidim::Moderation.create!(reportable: hidden, participatory_space: document.participatory_space, hidden_at: Time.current)
    create(:comment, commentable: block, author: user, body: { en: "Paragraph" })
    create(:comment, commentable: record, author: user, body: { en: "Proposal" })
    stats = Decidim::EnhancedTextwork::DocumentStats.new(document, user)
    expect(stats.counts[block.id]).to eq(likes: 0, comments: 1, suggestions: 1)
    # Additional blocks are imported legacy fixtures; the published original is locked.
    99.times do |index|
      document.blocks.create!(component: document.component, kind: "paragraph", position: index + 3, body: { en: "Paragraph #{index}" })
    end
    queries = []
    callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:cached] }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      document.reload
      stats = Decidim::EnhancedTextwork::DocumentStats.new(document, user)
      stats.blocks.each(&:number)
    end
    expect(stats.paragraphs.size).to eq(100)
    expect(queries.size).to be <= 6
  end

  it "renders 100 paragraphs with a query count independent of paragraph count" do
    app_routes = Decidim::EngineRouter.main_proxy(document.component)
    get app_routes.document_path(document)
    measure = lambda do
      queries = []
      callback = ->(_name, _start, _finish, _id, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:cached] }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { get app_routes.document_path(document) }
      expect(response).to have_http_status(:ok)
      queries.size
    end
    baseline = measure.call
    99.times do |index|
      document.blocks.create!(component: document.component, kind: "paragraph", position: index + 3, body: { en: "Paragraph #{index}" })
    end
    expanded = measure.call
    expect(expanded).to be <= baseline + 2
    expect(Nokogiri::HTML(response.body).css("[data-block-pill]").size).to eq(100)
  end

  it "keeps Core paragraph and suggestion replies, editing and comment votes working while open" do
    app_routes = Decidim::EngineRouter.main_proxy(document.component)
    comment_routes = Decidim::Comments::Engine.routes.url_helpers
    post app_routes.block_suggestions_path(block), params: { body: "Trees and benches.", expected_version: 1 }
    proposal = block.suggestions.last!
    [block, proposal].each do |resource|
      post comment_routes.comments_path(format: :js), params: { comment: { commentable_gid: resource.to_sgid.to_s, body: "A comment", alignment: 0 } }, headers: xhr
      expect(response).to have_http_status(:ok)
      comment = resource.comments.last!
      expect(comment.body.fetch("en")).to eq("A comment")
      patch comment_routes.comment_path(comment, format: :js), params: { comment: { body: "An edited comment" } }, headers: xhr
      expect(response).to have_http_status(:ok)
      sign_in admin
      post comment_routes.comments_path(format: :js), params: { comment: { commentable_gid: comment.to_sgid.to_s, body: "A reply", alignment: 0 } }, headers: xhr
      expect(response).to have_http_status(:ok)
      expect(comment.replies.last!.root_commentable).to eq(resource)
      post comment_routes.comment_votes_path(comment, format: :js), params: { weight: 1 }, headers: xhr
      expect(response).to have_http_status(:ok)
      expect(comment.reload.up_votes.count).to eq(1)
      sign_in user
    end
    expect(block.reload.comments_count).to eq(2)
    expect(proposal.reload.comments_count).to eq(2)
  end
end
