# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A form object to be used when admin users want to create a paragraph
      # through the participatory texts.
      class ParticipatoryTextParagraphForm < Admin::ParagraphBaseForm
        attribute :title, String
        attribute :body, String
        validates :title, length: { maximum: 150 }, presence: true

        def map_model(model)
          self.title = translated_attribute(model.title)
          self.body = translated_attribute(model.body)
        end
      end
    end
  end
end
