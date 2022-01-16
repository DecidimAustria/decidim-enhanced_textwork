# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # A form object to be used when admin users wants to merge two or more
      # paragraphs into a new one to another paragraph component in the same space.
      class ParagraphsMergeForm < ParagraphsForkForm
        validates :paragraphs, length: { minimum: 2 }
      end
    end
  end
end
