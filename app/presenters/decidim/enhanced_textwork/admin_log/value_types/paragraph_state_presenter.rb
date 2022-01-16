# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module AdminLog
      module ValueTypes
        class ParagraphStatePresenter < Decidim::Log::ValueTypes::DefaultPresenter
          def present
            return unless value

            h.t(value, scope: "decidim.enhanced_textwork.admin.paragraph_answers.edit", default: value)
          end
        end
      end
    end
  end
end
