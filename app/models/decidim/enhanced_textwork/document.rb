# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Document < ApplicationRecord
      self.table_name = "decidim_textwork_documents"
      include Decidim::Resourceable
      include Decidim::HasComponent
      include Decidim::Publicable
      include Decidim::SoftDeletable
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Searchable
      include Decidim::Likeable
      include Decidim::Followable
      include OriginalLanguage

      after_restore :try_update_index_for_search_resource, :update_comment_search_indexes
      after_update :update_comment_search_indexes, if: -> { saved_change_to_published_at? || saved_change_to_deleted_at? }

      paper_trail_options[:only] = %w(title description published_at deleted_at)
      has_many :blocks, class_name: "Decidim::EnhancedTextwork::Block", inverse_of: :document # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      has_many :document_revisions, class_name: "Decidim::EnhancedTextwork::DocumentRevision" # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      validates :locale, inclusion: { in: ->(record) { record.organization.available_locales } }
      def visible? = published? && !deleted? && component.published? && participatory_space.visible?

      def likeable? = false

      def followable? = visible?

      def allow_resource_permissions? = true

      # Check stored contributions, including removed blocks, withdrawn proposals
      # and hidden/deleted comments. Public counters cannot enforce this rule.
      def participation?
        suggestions = Suggestion.where(block: blocks)
        return true if suggestions.exists?

        return true if stored_comments.exists?

        Decidim::Like.where(resource: self)
                     .or(Decidim::Like.where(resource_type: Block.name, resource_id: blocks.select(:id)))
                     .or(Decidim::Like.where(resource_type: Suggestion.name, resource_id: suggestions.select(:id))).exists?
      end

      def original_editable? = !published? && !deleted? && !participation?

      def withdrawable? = !deleted? && !participation?

      def presenter = TextPresenter.new(self)

      def self.log_presenter_class_for(_log) = Decidim::EnhancedTextwork::AdminLog::DocumentPresenter

      def document = self

      def self.translatable_fields_list = [:title, :description]

      def numbering
        headings = [0, 0, 0]
        paragraph = 0
        source = numbered_blocks
        source.each_with_object({}) do |block, numbers|
          if block.heading?
            depth = block.heading_depth - 1
            headings[depth] += 1
            ((depth + 1)..2).each { |idx| headings[idx] = 0 }
            paragraph = 0
            numbers[block.id] = headings[0..depth].reject(&:zero?).join(".")
          elsif block.paragraph?
            paragraph += 1
            numbers[block.id] = (headings.reject(&:zero?) + [paragraph]).join(".")
          end
        end
      end
      component_manifest_name "textwork"
      searchable_fields({ participatory_space: { component: :participatory_space }, A: :title, D: :searchable_body, datetime: :published_at },
                        index_on_create: ->(document) { document.visible? }, index_on_update: ->(document) { document.visible? })
      def searchable_body
        { locale => blocks.active.ordered.map(&:original).join("\n") }
      end
      validates :title, presence: true

      private

      def numbered_blocks
        return blocks.active.ordered unless blocks.loaded?

        blocks.target.reject(&:removed?).sort_by { |block| [block.position, block.id] }
      end

      def stored_comments
        suggestions = Suggestion.where(block: blocks)
        Decidim::Comments::Comment.where(root_commentable: self)
                                  .or(Decidim::Comments::Comment.where(decidim_root_commentable_type: Block.name, decidim_root_commentable_id: blocks.select(:id)))
                                  .or(Decidim::Comments::Comment.where(decidim_root_commentable_type: Suggestion.name, decidim_root_commentable_id: suggestions.select(:id)))
      end

      def update_comment_search_indexes
        stored_comments.find_each(&:try_update_index_for_search_resource)
      end
    end
  end
end
