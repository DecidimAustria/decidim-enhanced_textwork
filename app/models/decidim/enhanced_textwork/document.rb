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

      after_restore :try_update_index_for_search_resource

      paper_trail_options[:only] = %w(title description published_at deleted_at)
      has_many :blocks, class_name: "Decidim::EnhancedTextwork::Block", inverse_of: :document # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      has_many :document_revisions, class_name: "Decidim::EnhancedTextwork::DocumentRevision" # rubocop:disable Rails/HasManyOrHasOneDependent -- retain history on soft deletion
      validates :locale, inclusion: { in: ->(record) { record.organization.available_locales } }
      def visible? = published? && !deleted? && component.published? && participatory_space.visible?

      def likeable? = visible? && !blocks.active.exists?(kind: "heading")

      def followable? = likeable?

      def allow_resource_permissions? = true

      def presenter = TextPresenter.new(self)

      def self.log_presenter_class_for(_log) = Decidim::EnhancedTextwork::AdminLog::DocumentPresenter

      def document = self

      def self.translatable_fields_list = [:title, :description]

      def numbering
        headings = [0, 0, 0]
        paragraph = 0
        blocks.active.ordered.each_with_object({}) do |block, numbers|
          if block.heading?
            depth = block.heading_depth - 1
            headings[depth] += 1
            ((depth + 1)..2).each { |idx| headings[idx] = 0 }
            paragraph = 0
            numbers[block.id] = headings[0..depth].reject(&:zero?).join(".")
          else
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
    end
  end
end
