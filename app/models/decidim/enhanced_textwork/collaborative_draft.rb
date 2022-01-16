# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class CollaborativeDraft < EnhancedTextwork::ApplicationRecord
      include Decidim::Resourceable
      include Decidim::Coauthorable
      include Decidim::HasComponent
      include Decidim::ScopableResource
      include Decidim::HasReference
      include Decidim::HasCategory
      include Decidim::Reportable
      include Decidim::HasAttachments
      include Decidim::Followable
      include Decidim::EnhancedTextwork::CommentableCollaborativeDraft
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Randomable

      has_many :collaborator_requests,
               class_name: "Decidim::EnhancedTextwork::CollaborativeDraftCollaboratorRequest",
               foreign_key: :decidim_enhanced_textwork_collaborative_draft_id,
               dependent: :destroy

      has_many :requesters,
               through: :collaborator_requests,
               source: :user,
               class_name: "Decidim::User",
               foreign_key: :decidim_user_id

      geocoded_by :address

      scope :open, -> { where(state: "open") }
      scope :withdrawn, -> { where(state: "withdrawn") }
      scope :except_withdrawn, -> { where.not(state: "withdrawn").or(where(state: nil)) }
      scope :published, -> { where(state: "published") }

      # Checks whether the user can edit the given paragraph.
      #
      # user - the user to check for authorship
      def editable_by?(user)
        authored_by?(user)
      end

      def open?
        state == "open"
      end

      def withdrawn?
        state == "withdrawn"
      end

      def published?
        state == "published"
      end

      # Public: Overrides the `reported_content_url` Reportable concern method.
      def reported_content_url
        ResourceLocatorPresenter.new(self).url
      end

      # Public: Overrides the `reported_attributes` Reportable concern method.
      def reported_attributes
        [:body]
      end

      # Public: Overrides the `reported_searchable_content_extras` Reportable concern method.
      def reported_searchable_content_extras
        [authors.map(&:name).join("\n")]
      end
    end
  end
end
