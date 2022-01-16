# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe EmendationPromotedEvent do
      let!(:component) { create(:paragraph_component) }
      let!(:amendable) { create(:paragraph, component: component, title: "My super paragraph") }
      let!(:emendation) { create(:paragraph, component: component, title: "My super emendation") }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }
      let(:amendable_type) { "paragraph" }

      include_examples "amendment promoted event"
    end
  end
end
