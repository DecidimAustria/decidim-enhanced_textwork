# frozen_string_literal: true

require "cell/partial"

module Decidim
  module EnhancedTextwork
    # This cell renders the link to the published paragraph of a collaborative draft.
    class CollaborativeDraftLinkToParagraphCell < Decidim::ViewModel
      def show
        render if paragraph
      end

      private

      def paragraph
        @paragraph ||= model.linked_resources(:paragraph, "created_from_collaborative_draft").first
      end

      def link_to_resource
        link_to resource_locator(paragraph).path, class: "button secondary light expanded button--sc mt-s" do
          t("published_paragraph", scope: "decidim.enhanced_textwork.collaborative_drafts.show")
        end
      end

      def link_header
        tag.strong(class: "text-large") do
          t("final_paragraph", scope: "decidim.enhanced_textwork.collaborative_drafts.show")
        end
      end

      def link_help_text
        tag.span(class: "text-medium") do
          t("final_paragraph_help_text", scope: "decidim.enhanced_textwork.collaborative_drafts.show")
        end
      end

      def link_to_versions
        @path ||= decidim_enhanced_textwork.collaborative_draft_versions_path(
          collaborative_draft_id: model.id
        )
        link_to @path, class: "text-medium" do
          tag.u do
            t("version_history", scope: "decidim.enhanced_textwork.collaborative_drafts.show")
          end
        end
      end

      def decidim
        Decidim::Core::Engine.routes.url_helpers
      end

      def decidim_enhanced_textwork
        Decidim::EngineRouter.main_proxy(model.component)
      end
    end
  end
end
