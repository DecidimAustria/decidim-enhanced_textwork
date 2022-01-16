# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    #
    # A dummy presenter to abstract out the author of an official paragraph.
    #
    class OfficialAuthorPresenter < Decidim::OfficialAuthorPresenter
      def name
        I18n.t("decidim.enhanced_textwork.models.paragraph.fields.official_paragraph")
      end
    end
  end
end
