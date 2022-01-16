# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module EnhancedTextwork
    module Admin
      module Picker
        extend ActiveSupport::Concern

        included do
          helper Decidim::EnhancedTextwork::Admin::ParagraphsPickerHelper
        end

        def paragraphs_picker
          render :paragraphs_picker, layout: false
        end
      end
    end
  end
end
