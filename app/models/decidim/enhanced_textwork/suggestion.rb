# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Suggestion < ApplicationRecord
      self.table_name = "decidim_textwork_suggestions"
      include Decidim::Resourceable
      include Decidim::HasComponent
      include Decidim::Authorable
      include Decidim::Comments::CommentableWithComponent
      include Decidim::Likeable
      include Decidim::Reportable
      include Decidim::Traceable
      include Decidim::Loggable
      include OriginalLanguage

      component_manifest_name "textwork"
      paper_trail_options[:only] = %w(body justification answer status)
      belongs_to :block, class_name: "Decidim::EnhancedTextwork::Block", inverse_of: :suggestions
      belongs_to :block_version, class_name: "Decidim::EnhancedTextwork::BlockVersion"
      belongs_to :decided_by, class_name: "Decidim::User", optional: true
      delegate :document, to: :block
      scope :listed, -> { not_hidden.where.not(status: "withdrawn") }
      validates :status, inclusion: { in: %w(pending accepted rejected withdrawn) }
      validate :valid_content

      def pending? = status == "pending"

      def outdated? = pending? && block_version.number < block.current_version_number

      def editable_by?(user)
        withdrawable_by?(user) && feedback_received_at.nil? && likes_count.zero? && comments_count.zero?
      end

      def withdrawable_by?(user) = pending? && authored_by?(user) && visible? && Participation.open?(component, :suggestions)

      def visible? = block.visible? && !hidden? && status != "withdrawn"

      def published? = document.published?

      def likeable? = visible?

      def allow_resource_permissions? = true

      def comments_have_votes? = true

      def commentable? = visible? && component.settings.comments_enabled?

      def title = { original_locale => I18n.t("decidim.textwork.suggestion_by", name: author&.name, number: block.number) }

      def presenter = TextPresenter.new(self)

      def reported_attributes = [:body, :justification]

      def self.translatable_fields_list = [:body, :justification, :answer]

      def self.log_presenter_class_for(_log) = Decidim::EnhancedTextwork::AdminLog::SuggestionPresenter

      def users_to_notify_on_comment_created = [author].compact

      def accepts_new_comments? = commentable? && Participation.open?(component, :comments)

      def user_allowed_to_comment?(user) = accepts_new_comments? && Access.allowed?(user, self, :comment)

      def user_allowed_to_vote_comment?(user) = accepts_new_comments? && Access.allowed?(user, self, :vote_comment)

      # Core invokes this when a comment is created/removed; the first feedback
      # timestamp must never be cleared when feedback is later removed.
      def update_comments_count
        count = comments.not_hidden.not_deleted.count
        values = { comments_count: count, updated_at: Time.current }
        values[:feedback_received_at] = Time.current if count.positive? && feedback_received_at.nil?
        update_columns(values) # rubocop:disable Rails/SkipsModelValidations -- Core counter hook must not create a text version
      end

      def self.normalize(text)
        text.to_s.gsub(/\r\n?/, "\n").split("\n").map { |line| line.strip.gsub(/[ \t]+/, " ") }.join("\n").strip
      end

      private

      def valid_content
        errors.add(:body, :blank) if original.blank?
        errors.add(:body, :too_long, count: 5000) if original.length > 5000
        errors.add(:justification, :too_long, count: 1000) if original(:justification).length > 1000
        validate_changeset
        errors.add(:answer, :blank) if status == "rejected" && original(:answer).blank?
      end

      def validate_changeset
        errors.add(:body, :unchanged) if self.class.normalize(changeset["original"]) == self.class.normalize(changeset["replace"])
        errors.add(:body, :invalid) if changeset["replace"] != original
        errors.add(:block_version, :invalid) if block_version && (block_version.block != block || changeset["original"] != block_version.body)
        validate_block
      end

      def validate_block
        errors.add(:block, :invalid) unless block&.paragraph?
        errors.add(:component, :invalid) if block && component != block.component
      end
    end
  end
end
