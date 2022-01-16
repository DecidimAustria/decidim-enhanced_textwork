# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe Paragraph do
      subject { paragraph }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "paragraphs") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, :admin, organization: organization) }
      let!(:paragraph) { create(:paragraph, component: component, users: [author]) }
      let(:resource) do
        build(:dummy_resource)
      end

      context "when event is created" do
        before do
          link_name = "included_paragraphs"
          event_name = "decidim.resourceable.#{link_name}.created"
          payload = {
            from_type: "Decidim::Accountability::Result", from_id: resource.id,
            to_type: paragraph.class.name, to_id: paragraph.id
          }
          ActiveSupport::Notifications.instrument event_name, this: payload do
            Decidim::ResourceLink.create!(
              from: resource,
              to: resource,
              name: link_name,
              data: {}
            )
          end
        end

        it "is accepted" do
          paragraph.reload
          expect(paragraph.state).to eq("accepted")
        end
      end
    end
  end
end
