# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe ParagraphForm do
        it_behaves_like "a paragraph form", skip_etiquette_validation: true, i18n: true, address_optional_with_geocoding: true
        it_behaves_like "a paragraph form with meeting as author", skip_etiquette_validation: true, i18n: true
      end
    end
  end
end
