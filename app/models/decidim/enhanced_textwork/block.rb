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
      belongs_to :editor_image, class_name: "Decidim::EditorImage", optional: true
      has_many :block_versions, -> { order(:number) }, class_name: "Decidim::EnhancedTextwork::BlockVersion", inverse_of: :block # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      has_many :suggestions, class_name: "Decidim::EnhancedTextwork::Suggestion", inverse_of: :block # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      scope :active, -> { where(removed_at: nil) }
      scope :ordered, -> { order(:position, :id) }
      validates :kind, inclusion: { in: %w(heading paragraph image) }
      validates :image_alt, length: { maximum: 2000 }
      validates :heading_depth, inclusion: { in: 1..3 }
      validates :position, numericality: { only_integer: true, greater_than: 0 }
      validate do
        errors.add(:body, :blank) if original.blank? && !image?
        errors.add(:component, :invalid) if component != document&.component
        errors.add(:editor_image, :invalid) if image? && (!editor_image&.file&.attached? || editor_image.organization != document.organization)
        errors.add(:editor_image, :invalid) if !image? && editor_image
      end

      def self.translatable_fields_list = [:body]

      def heading? = kind == "heading"

      def paragraph? = kind == "paragraph"

      def image? = kind == "image"

      def display_image = editor_image.file.variant(resize_to_limit: [1600, 1600])

      def missing_image_description?
        image? && (image_alt.blank? || image_alt.downcase == editor_image.file.filename.base.to_s.tr("_-", "  ").squish.downcase)
      end

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

      def notification_scope = document

      def users_to_notify_on_comment_created = notification_scope.followers.to_a

      def pending_suggestions_count = suggestions.not_hidden.where(status: "pending").count

      def likeable? = paragraph? && visible?

      def followable? = false

      def commentable? = paragraph? && visible? && component.settings.comments_enabled?

      def accepts_new_comments? = commentable? && Participation.open?(component, :comments)

      def user_allowed_to_comment?(user) = accepts_new_comments? && Access.allowed?(user, self, :comment)

      def user_allowed_to_vote_comment?(user) = accepts_new_comments? && Access.allowed?(user, self, :vote_comment)
    end
  end
end
