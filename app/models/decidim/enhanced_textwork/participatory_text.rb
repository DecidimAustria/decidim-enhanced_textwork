# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Contains the meta data of the document, like title and description.
    #
    class ParticipatoryText < EnhancedTextwork::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::TranslatableResource

      translatable_fields :title, :description
    end
  end
end
