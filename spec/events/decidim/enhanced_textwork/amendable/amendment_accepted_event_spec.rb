# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe AmendmentAcceptedEvent do
      let!(:component) { create(:paragraph_component) }
      let!(:amendable) { create(:paragraph, component: component, title: "My super paragraph") }
      let!(:emendation) { create(:paragraph, component: component, title: "My super emendation") }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }

      include_examples "amendment accepted event"
    end
  end
end
