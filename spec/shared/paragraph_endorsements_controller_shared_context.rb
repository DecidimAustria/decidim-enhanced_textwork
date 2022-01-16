# frozen_string_literal: true

RSpec.shared_context "when in a paragraph" do
  routes { Decidim::EnhancedTextwork::Engine.routes }

  let(:paragraph) { create(:paragraph, component: component) }
  let(:user) { create(:user, :confirmed, organization: component.organization) }
  let(:params) do
    {
      paragraph_id: paragraph.id,
      component_id: component.id,
      participatory_process_slug: component.participatory_space.slug
    }
  end

  before do
    request.env["decidim.current_organization"] = component.organization
    request.env["decidim.current_component"] = component
    request.env["decidim.current_participatory_space"] = component.participatory_space
    sign_in user
  end
end
