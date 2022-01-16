# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe UpdateDraft do
      let!(:component) { create(:paragraph_component) }
      let!(:other_user) { create(:user, :confirmed, organization: component.organization) }

      let!(:amendable) { create(:paragraph, component: component) }
      let!(:emendation) { create(:paragraph, :unpublished, component: component) }
      let!(:amendment) { create(:amendment, :draft, amendable: amendable, emendation: emendation) }

      let(:title) { "More sidewalks and less roads!" }
      let(:body) { "Everything would be better" }
      let(:params) do
        {
          id: amendment.id,
          emendation_params: { title: title, body: body }
        }
      end

      let(:current_user) { amendment.amender }
      let(:context) do
        {
          current_user: current_user,
          current_organization: component.organization
        }
      end

      let(:form) { Decidim::Amendable::EditForm.from_params(params).with_context(context) }
      let(:command) { described_class.new(form) }

      include_examples "update amendment draft"
    end
  end
end
