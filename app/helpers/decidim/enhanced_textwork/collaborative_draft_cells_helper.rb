# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Custom helpers, scoped to the paragraphs engine.
    #
    module CollaborativeDraftCellsHelper
      include Decidim::EnhancedTextwork::ApplicationHelper
      include Decidim::EnhancedTextwork::Engine.routes.url_helpers
      include Decidim::LayoutHelper
      include Decidim::ApplicationHelper
      include Decidim::TranslationsHelper
      include Decidim::ResourceReferenceHelper
      include Decidim::TranslatableAttributes
      include Decidim::CardHelper

      delegate :title, :state, to: :model

      def has_actions?
        false
      end

      def current_settings
        model.component.current_settings
      end

      def component_settings
        model.component.settings
      end

      def current_component
        model.component
      end

      def from_context
        @options[:from]
      end

      def badge_name
        humanize_collaborative_draft_state state
      end

      def state_classes
        [collaborative_draft_state_badge_css_class(state).to_s]
      end
    end
  end
end
