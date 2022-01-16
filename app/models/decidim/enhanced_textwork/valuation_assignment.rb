# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # A valuation assignment links a paragraph and a Valuator user role.
    # Valuators will be users in charge of defining the monetary cost of a
    # paragraph.
    class ValuationAssignment < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :paragraph, foreign_key: "decidim_paragraph_id", class_name: "Decidim::EnhancedTextwork::Paragraph"
      belongs_to :valuator_role, polymorphic: true

      def self.log_presenter_class_for(_log)
        Decidim::EnhancedTextwork::AdminLog::ValuationAssignmentPresenter
      end

      def valuator
        valuator_role.user
      end
    end
  end
end
