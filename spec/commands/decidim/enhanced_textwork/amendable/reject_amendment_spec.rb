# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe Reject do
      let!(:component) { create(:paragraph_component) }
      let!(:amendable) { create(:paragraph, component: component) }
      let!(:emendation) { create(:paragraph, component: component) }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }
      let(:command) { described_class.new(form) }

      let(:form) { Decidim::Amendable::RejectForm.from_params(form_params).with_context(form_context) }

      let(:form_params) do
        {
          id: amendment.id
        }
      end

      let(:form_context) do
        {
          current_organization: component.organization,
          current_user: amendable.creator_author,
          current_component: component,
          current_participatory_space: component.participatory_space
        }
      end

      include_examples "reject amendment" do
        it "changes the emendation state" do
          expect { command.call }.to change { emendation.reload[:state] }.from(nil).to("rejected")
        end
      end
    end
  end
end
