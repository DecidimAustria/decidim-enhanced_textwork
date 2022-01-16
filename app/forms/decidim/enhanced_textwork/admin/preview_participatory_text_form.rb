# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A form object to be used when admin users want to review a collection of paragraphs
      # from a participatory text.
      class PreviewParticipatoryTextForm < Decidim::Form
        attribute :paragraphs, Array[Decidim::EnhancedTextwork::Admin::ParticipatoryTextParagraphForm]

        def from_models(paragraphs)
          self.paragraphs = paragraphs.collect do |paragraph|
            Admin::ParticipatoryTextParagraphForm.from_model(paragraph)
          end
        end

        def paragraphs_attributes=(attributes); end
      end
    end
  end
end
