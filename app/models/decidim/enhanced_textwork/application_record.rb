# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ApplicationRecord < Decidim::ApplicationRecord
      self.abstract_class = true
    end
  end
end
