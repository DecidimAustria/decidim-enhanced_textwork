# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A form object to be used when admin users want to create a paragraph.
      class ParagraphNoteForm < Decidim::Form
        mimic :paragraph_note

        attribute :body, String

        validates :body, presence: true
      end
    end
  end
end
