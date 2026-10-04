# frozen_string_literal: true

require "spec_helper"
RSpec.describe "Standalone Textwork", type: :request do
  let!(:section) { create(:textwork_section) }
  let(:component) { section.component }
  let(:organization) { component.organization }
  let(:routes) { Decidim::EngineRouter.main_proxy(component) }
  let(:user) { create(:user, :confirmed, organization:) }
  before { host! organization.host }

  it "renders its own document, contents and core comment form" do
    get routes.textwork_path(locale: :en, paragraph_id: section.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("More trees", "textwork-discussion", "comments", 'aria-current="location"')
  end
  it "renders its own version history and immutable text" do
    get routes.section_path(section, locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Version 1", "Previous versions")
  end
  it "does not disclose another component's sections" do
    other = create(:textwork_section)
    get routes.textwork_path(locale: :en, paragraph_id: other.id)
    expect(response).to have_http_status(:not_found)
  end
  it "does not disclose unpublished documents" do
    section.document.update!(published_at: nil)
    get routes.section_path(section, locale: :en)
    expect(response).to have_http_status(:not_found)
  end
  it "excludes moderated sections" do
    create(:moderation, reportable: section, hidden_at: Time.current)
    get routes.textwork_path(locale: :en, paragraph_id: section.id)
    expect(response).to have_http_status(:not_found)
  end
  it "supports exactly one version and allows withdrawal" do
    sign_in user
    2.times { post routes.section_support_path(section, locale: :en), params: { revision_id: section.current_revision_id } }
    expect(response).to have_http_status(:redirect)
    expect(section.current_revision.supports.where(author: user).count).to eq(1)
    delete routes.section_support_path(section, locale: :en), params: { revision_id: section.current_revision_id }
    expect(section.current_revision.supports.where(author: user)).to be_empty
  end
  it "rejects supports when the phase is blocked" do
    component.update!(default_step_settings: { supports_blocked: true })
    sign_in user
    post routes.section_support_path(section, locale: :en), params: { revision_id: section.current_revision_id }
    expect(response).to have_http_status(:forbidden)
    expect(section.current_revision.supports).to be_empty
  end
  it "requires login to support" do
    post routes.section_support_path(section, locale: :en), params: { revision_id: section.current_revision_id }
    expect(response).to have_http_status(:redirect)
    expect(section.current_revision.supports).to be_empty
  end
  it "creates an independent amendment and renders its discussion" do
    sign_in user
    post routes.section_amendments_path(section, locale: :en),
         params: { base_revision_id: section.current_revision_id, body: "<p>More shade.</p>", reason: "Summer heat" }
    expect(response).to have_http_status(:redirect)
    amendment = section.amendments.last!
    expect(amendment.author).to eq(user)
    get routes.amendment_path(amendment, locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Summer heat", "More shade", "Original text", "comments")
  end
  it "rejects an amendment based on an obsolete revision" do
    old = section.current_revision
    revision = section.revisions.create!(author: user, number: 2, title: old.title, body: { en: "New version" })
    section.update!(current_revision: revision)
    sign_in user
    post routes.section_amendments_path(section, locale: :en), params: { base_revision_id: old.id, body: "Changed" }
    expect(response).to have_http_status(:conflict)
    expect(section.amendments).to be_empty
    post routes.section_support_path(section, locale: :en), params: { revision_id: old.id }
    expect(response).to have_http_status(:conflict)
  end
  it "does not accept amendments when disabled" do
    component.update!(settings: component.settings.to_h.merge(amendments_enabled: false))
    sign_in user
    post routes.section_amendments_path(section, locale: :en), params: { base_revision_id: section.current_revision_id, body: "Changed" }
    expect(response).to have_http_status(:forbidden)
  end
end
