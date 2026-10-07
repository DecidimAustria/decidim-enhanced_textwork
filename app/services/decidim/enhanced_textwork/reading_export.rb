# frozen_string_literal: true

require "decidim/enhanced_textwork/word_document"
module Decidim
  module EnhancedTextwork
    class ReadingExport
      class MissingTranslation < StandardError; end

      def initialize(document, locale)
        @document = document
        @locale = locale.to_s
        @word = WordDocument.new
      end

      def export
        prepare_translations!
        I18n.with_locale(@locale) do
          @word.paragraph(text(@document, :title), heading: true)
          @word.html(Markdown.render(text(@document, :description)))
          @word.paragraph("#{t("liked")}: #{@document.likes_count}") if @document.likeable?
          @document.blocks.active.ordered.each do |block|
            if block.image?
              @word.paragraph(t("images.export", alt: block.image_alt))
            elsif block.heading?
              @word.paragraph("#{block.number} #{text(block)}", heading: true)
            else
              @word.paragraph(t("paragraph", number: block.number), heading: true)
              @word.html(Markdown.render(text(block)))
              @word.paragraph(t("export_likes", count: block.likes_count))
              comments(block)
              block.suggestions.listed.where(status: "pending").order(likes_count: :desc, created_at: :asc, id: :asc).each do |suggestion|
                @word.paragraph(t("by", name: suggestion.author.name), heading: true)
                @word.paragraph(I18n.l(suggestion.created_at.to_date))
                @word.paragraph(t("export_likes", count: suggestion.likes_count))
                @word.html(Markdown.render(text(suggestion)))
                @word.html(Markdown.render(text(suggestion, :justification)))
                comments(suggestion)
              end
            end
          end
        end
        @word.render
      end

      private

      # Queue every missing field in one pass, instead of making users retry an
      # export once for each paragraph. Comments retain Core translation policy.
      def prepare_translations!
        missing = false
        fields = [[@document, :title], [@document, :description]]
        @document.blocks.active.ordered.each do |block|
          next if block.image?

          fields << [block, :body]
          resources = [block] + block.suggestions.listed.where(status: "pending").to_a
          resources.drop(1).each { |suggestion| fields.push([suggestion, :body], [suggestion, :justification]) }
          missing ||= resources.any? { |resource| missing_comment_translation?(resource) }
        end
        fields.each do |resource, field|
          text(resource, field)
        rescue MissingTranslation
          missing = true
        end
        raise MissingTranslation if missing
      end

      def missing_comment_translation?(resource) = resource.comments.not_hidden.not_deleted.any? { |comment| comment_text(comment).blank? }

      def comment_text(comment)
        comment.body[@locale].presence || comment.body.dig("machine_translations", @locale).presence
      end

      def t(key, **) = I18n.t("decidim.textwork.#{key}", **)

      def text(resource, field = :body)
        return resource.original(field) if @locale == resource.original_locale
        return "" if resource.original(field).blank?

        value = resource[field].to_h[@locale].presence || resource[field].to_h.dig("machine_translations", @locale).presence
        return value if value

        TranslationRequest.request(resource, field, @locale)
        # Never silently mix languages in an export advertised as monolingual.
        raise MissingTranslation
      end

      def comments(resource)
        resource.comments.not_hidden.not_deleted.order(:created_at).each do |comment|
          body = comment_text(comment)
          raise MissingTranslation unless body

          @word.paragraph("#{comment.author.name} · #{I18n.l(comment.created_at.to_date)}", indent: comment.depth)
          @word.html(body, indent: comment.depth)
        end
      end
    end
  end
end
