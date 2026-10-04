# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Textwork", type: :request do
  let(:organization) { create(:organization, available_locales: %w(en de), default_locale: "en") }
  let(:space) { create(:participatory_process, organization:) }
  let(:component) do
    create(:proposal_component, :published, participatory_space: space,
           settings: { participatory_texts_enabled: true, enhanced_textwork_enabled: true })
  end
  let(:routes) { Decidim::EngineRouter.main_proxy(component) }
  let!(:paragraph) { create(:proposal, component:, title: { en: "1" }, body: { en: "Visible textwork paragraph" }, participatory_text_level: "article") }

  before { host! organization.host }

  it "redirects only enabled proposal components to the textwork view" do
    get routes.proposals_path(locale: :en)
    expect(response).to redirect_to(routes.textwork_path(locale: :en))
  end

  it "renders the document and the core discussion for the selected paragraph" do
    get routes.textwork_path(locale: :en, paragraph_id: paragraph.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Visible textwork paragraph", "textwork-discussion", "comments")
    expect(response.body).not_to include('<h3 class="h4">1</h3>')
  end

  it "preserves the standard proposal view when textwork is disabled" do
    component.update!(settings: component.settings.to_h.merge(enhanced_textwork_enabled: false))
    get routes.proposals_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('class="textwork"')
    get routes.textwork_path(locale: :en)
    expect(response).to have_http_status(:not_found)
  end

  it "requires participatory texts to be enabled too" do
    component.update!(settings: component.settings.to_h.merge(participatory_texts_enabled: false))
    get routes.textwork_path(locale: :en)
    expect(response).to have_http_status(:not_found)
  end

  it "does not reveal another component's paragraph" do
    other = create(:proposal)
    get routes.textwork_path(locale: :en, paragraph_id: other.id)
    expect(response).to have_http_status(:not_found)
  end

  it "does not expose draft paragraphs" do
    paragraph.update!(published_at: nil)
    get routes.textwork_path(locale: :en, paragraph_id: paragraph.id)
    expect(response).to have_http_status(:not_found)
  end

  it "excludes moderated paragraphs from the document and selection" do
    hidden = create(:proposal, :hidden, component:, body: { en: "Hidden paragraph" }, participatory_text_level: "article")
    get routes.textwork_path(locale: :en)
    expect(response.body).not_to include("Hidden paragraph")
    get routes.textwork_path(locale: :en, paragraph_id: hidden.id)
    expect(response).to have_http_status(:not_found)
  end

  it "uses the core voting controls for a signed-in participant" do
    component.update!(default_step_settings: { votes_enabled: true })
    user = create(:user, :confirmed, organization:)
    sign_in user
    get routes.textwork_path(locale: :en)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("proposal-#{paragraph.id}-vote-button", routes.proposal_proposal_vote_path(paragraph))
  end

  it "shows allowed amendment actions and hides moderated amendments" do
    component.update!(settings: component.settings.to_h.merge(amendments_enabled: true),
                      default_step_settings: { amendment_creation_enabled: true })
    visible = create(:proposal, component:, title: { en: "Visible amendment" })
    hidden = create(:proposal, :hidden, component:, title: { en: "Hidden amendment" })
    [visible, hidden].each { |emendation| create(:amendment, amendable: paragraph, emendation:) }
    get routes.textwork_path(locale: :en, paragraph_id: paragraph.id)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Suggest a change", "Visible amendment")
    expect(response.body).not_to include("Hidden amendment")
  end
end
