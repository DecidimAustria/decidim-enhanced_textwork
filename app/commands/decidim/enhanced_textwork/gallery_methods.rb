# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A module with all the gallery common methods for paragraphs
    # and collaborative draft commands.
    # Allows to create several image attachments at once
    module GalleryMethods
      include ::Decidim::GalleryMethods

      private

      def gallery_allowed?
        @form.current_component.settings.attachments_allowed?
      end
    end
  end
end
