# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"
require "decidim/core/test/shared_examples/input_filter_examples"

module Decidim
  module EnhancedTextwork
    describe ParagraphInputFilter, type: :graphql do
      include_context "with a graphql class type"
      let(:type_class) { Decidim::EnhancedTextwork::ParagraphsType }

      let(:model) { create(:paragraph_component) }
      let!(:models) { create_list(:paragraph, 3, :published, component: model) }

      context "when filtered by published_at" do
        include_examples "connection has before/since input filter", "paragraphs", "published"
      end
    end
  end
end
