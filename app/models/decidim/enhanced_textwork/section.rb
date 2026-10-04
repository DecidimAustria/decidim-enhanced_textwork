# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Section < ApplicationRecord
      self.table_name = "decidim_textwork_sections"
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
      def visible? = published? && component.published? && !hidden? && participatory_space.visible?
      prepend Decidim::EnhancedTextwork::CommentVisibility
      belongs_to :document, class_name: "Decidim::EnhancedTextwork::Document", inverse_of: :sections
      belongs_to :current_revision, class_name: "Decidim::EnhancedTextwork::Revision", optional: true
      has_many :revisions, -> { order(:number) }, class_name: "Decidim::EnhancedTextwork::Revision", inverse_of: :section
      has_many :amendments, class_name: "Decidim::EnhancedTextwork::Amendment", inverse_of: :section
      validates :level, inclusion: { in: %w(section sub-section article) }
      validates :position, numericality: { only_integer: true, greater_than: 0 }
      validate :same_component
      delegate :title, :body, :author, to: :current_revision, allow_nil: true
      def article? = level == "article"

      def same_component
        errors.add(:component, :invalid) if document && component != document.component
        errors.add(:current_revision, :invalid) if current_revision && current_revision.section_id != id
      end
    end
  end
end
