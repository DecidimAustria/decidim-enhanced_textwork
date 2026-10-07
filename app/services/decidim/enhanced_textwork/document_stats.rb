# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class DocumentStats
      attr_reader :blocks, :paragraphs, :counts, :numbers, :liked_ids, :chapter_counts

      def initialize(document, user = nil)
        @blocks = document.blocks.active.ordered.to_a
        @blocks.each do |block|
          block.document = document
          block.component = document.component
        end
        document.association(:blocks).target = @blocks
        document.association(:blocks).loaded!
        @paragraphs = @blocks.select(&:paragraph?)
        @numbers = document.numbering
        pending = Suggestion.not_hidden.where(block: @paragraphs, status: "pending").group(:block_id).count
        @counts = @paragraphs.to_h { |block| [block.id, { likes: block.likes_count, comments: block.comments_count, suggestions: pending.fetch(block.id, 0) }] }
        @liked_ids = user ? Decidim::Like.where(resource_type: Block.name, resource_id: @paragraphs.map(&:id), author: user).pluck(:resource_id).to_set : Set.new
        aggregate_chapters
      end

      def aggregate_chapters
        @chapter_counts = Hash.new(0)
        chapters = {}
        @blocks.each do |block|
          if block.heading?
            chapters.delete_if { |depth, _id| depth >= block.heading_depth }
            chapters[block.heading_depth] = block.id
          elsif block.paragraph?
            chapters.each_value { |id| @chapter_counts[id] += discussion_count(block) }
          end
        end
      end

      def summary = { paragraphs: paragraphs.size, comments: counts.values.sum { |value| value[:comments] }, suggestions: counts.values.sum { |value| value[:suggestions] } }

      def discussion_count(block) = counts.fetch(block.id).values_at(:comments, :suggestions).sum

      def most_discussed = paragraphs.select { |block| discussion_count(block).positive? }.sort_by { |block| [-discussion_count(block), block.position, block.id] }.first(3)

      def quiet = paragraphs.select { |block| discussion_count(block).zero? }
    end
  end
end
