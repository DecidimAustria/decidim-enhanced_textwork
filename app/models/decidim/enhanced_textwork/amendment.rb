# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Amendment < ApplicationRecord
      self.table_name = "decidim_textwork_amendments"
      include Decidim::Loggable
      include Decidim::Resourceable
      include Decidim::HasComponent
      include Decidim::Comments::CommentableWithComponent
      include Decidim::Reportable
      include Decidim::Followable
      component_manifest_name "textwork"
      def presenter = Decidim::EnhancedTextwork::TextPresenter.new(self)
      def allow_resource_permissions? = true
      def comments_have_votes? = true
      def users_to_notify_on_comment_created = followers
      def reported_attributes = [:title, :body]
      def published? = document.published?
      prepend Decidim::EnhancedTextwork::CommentVisibility
      belongs_to :section, class_name: "Decidim::EnhancedTextwork::Section", inverse_of: :amendments
      belongs_to :base_revision, class_name: "Decidim::EnhancedTextwork::Revision"
      belongs_to :result_revision, class_name: "Decidim::EnhancedTextwork::Revision", optional: true
      belongs_to :author, foreign_key: :decidim_author_id, class_name: "Decidim::User"
      belongs_to :decided_by, class_name: "Decidim::User", optional: true
      has_many :supports, as: :supportable, class_name: "Decidim::EnhancedTextwork::Support"
      delegate :document, to: :section
      validates :state, inclusion: { in: %w(pending accepted rejected withdrawn) }
      validates :title, :body, presence: true
      validate :consistent_references
      def self.log_presenter_class_for(_log) = Decidim::EnhancedTextwork::AdminLog::AmendmentPresenter
      def stale? = base_revision_id != section.current_revision_id
      def visible? = section.visible? && !hidden?

      def consistent_references
        errors.add(:base_revision, :invalid) if base_revision && base_revision.section != section
        errors.add(:component, :invalid) if section && component != section.component
        errors.add(:author, :invalid) if author && component && author.organization != organization
      end
    end
  end
end
