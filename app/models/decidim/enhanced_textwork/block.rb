# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Block < ApplicationRecord
      self.table_name = "decidim_textwork_blocks"
      include Decidim::Resourceable
      include Decidim::HasComponent
      include Decidim::Comments::CommentableWithComponent
      include Decidim::Likeable
      include Decidim::Followable
      include Decidim::Traceable
      include OriginalLanguage

      component_manifest_name "textwork"
      paper_trail_options[:only] = %w(body)

      belongs_to :document, -> { with_deleted }, class_name: "Decidim::EnhancedTextwork::Document", inverse_of: :blocks
      has_many :block_versions, -> { order(:number) }, class_name: "Decidim::EnhancedTextwork::BlockVersion", inverse_of: :block # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      has_many :suggestions, class_name: "Decidim::EnhancedTextwork::Suggestion", inverse_of: :block # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      scope :active, -> { where(removed_at: nil) }
      scope :ordered, -> { order(:position, :id) }
      validates :kind, inclusion: { in: %w(heading paragraph) }
      validates :heading_depth, inclusion: { in: 1..3 }
      validates :position, numericality: { only_integer: true, greater_than: 0 }
      validate do
        errors.add(:body, :blank) if original.blank?
        errors.add(:component, :invalid) if component != document&.component
      end

      def self.translatable_fields_list = [:body]

      def heading? = kind == "heading"

      def paragraph? = kind == "paragraph"

      def removed? = removed_at.present?

      def published? = document.published?

      def visible? = !removed? && document.visible?

      def title = { original_locale => heading? ? original : I18n.t("decidim.textwork.paragraph", number:) }

      def presenter = TextPresenter.new(self)

      def allow_resource_permissions? = true

      def comments_have_votes? = true

      def current_version = block_versions.find_by!(number: current_version_number)

      def number = document.numbering[id]

      def chapter = document.blocks.active.where(kind: "heading").where(position: ...position).order(position: :desc).first

      def notification_scope = heading? ? self : (chapter || document)

      def users_to_notify_on_comment_created = notification_scope.followers.to_a

      def pending_suggestions_count = suggestions.not_hidden.where(status: "pending").count

      def likeable? = heading? && visible?

      def followable? = likeable?

      def commentable? = paragraph? && !removed? && component.settings.comments_enabled?

      def accepts_new_comments? = commentable? && visible? && !component.current_settings.comments_blocked

      def user_allowed_to_comment?(user) = accepts_new_comments? && Access.allowed?(user, self, :comment)

      def user_allowed_to_vote_comment?(user) = accepts_new_comments? && Access.allowed?(user, self, :vote_comment)
    end
  end
end
