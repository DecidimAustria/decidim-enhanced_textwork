# frozen-string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class UpdateParagraphScopeEvent < Decidim::Events::SimpleEvent
        include Decidim::Events::AuthorEvent
      end
    end
  end
end
