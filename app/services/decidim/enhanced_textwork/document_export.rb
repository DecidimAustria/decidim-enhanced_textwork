# frozen_string_literal: true

require "decidim/enhanced_textwork/word_document"

module Decidim
  module EnhancedTextwork
    class DocumentExport
      def initialize(component, user, locale)
        @component = component
        @user = user
        @locale = locale.to_s
        @document = WordDocument.new
      end

      def export
        I18n.with_locale(@locale) do
          text = Document.find_by(component: @component)
          @document.paragraph(translate(text&.title || @component.name), heading: true)
          @document.html(translate(text.description)) if text
          paragraphs.each { |paragraph| write_paragraph(paragraph) }
        end
        @document.render
      end

      private

      def paragraphs
        Section.joins(:document).where(component: @component).where.not(decidim_textwork_documents: { published_at: nil }).not_hidden.order(:position, :id)
      end

      def write_paragraph(paragraph)
        title = translate(paragraph.title)
        title = t("paragraph", number: title) if title.match?(/\A\d+\z/)
        @document.paragraph(title, heading: true)
        @document.html(translate(paragraph.body)) if paragraph.article?
        @document.paragraph("#{t("state")}: v#{paragraph.current_revision.number}")
        @document.paragraph("#{t("supports")}: #{paragraph.current_revision.supports.count}")
        write_comments(paragraph)
        return unless @component.settings.amendments_enabled?

        amendments = paragraph.amendments.not_hidden.order(:created_at, :id)
        @document.paragraph(t("amendments"), heading: true) if amendments.any?
        amendments.each do |amendment|
          @document.paragraph("#{amendment.id}: #{translate(amendment.title)}", heading: true)
          @document.html(translate(amendment.body))
          @document.paragraph("#{t("state")}: #{amendment.state}")
          @document.paragraph("#{t("supports")}: #{amendment.supports.count}")
          write_comments(amendment)
        end
      end

      def write_comments(paragraph)
        comments = Decidim::Comments::Comment.where(root_commentable: paragraph).not_hidden.not_deleted.order(:created_at, :id)
        grouped = comments.group_by { |comment| [comment.decidim_commentable_type, comment.decidim_commentable_id] }
        roots = grouped.fetch([paragraph.class.name, paragraph.id], [])
        @document.paragraph(t("comments"), heading: true) if roots.any?
        roots.each { |comment| write_comment(comment, grouped, 0) }
      end

      def write_comment(comment, grouped, depth)
        return if depth > Decidim::Comments::Comment::MAX_DEPTH

        author = comment.author&.name.presence || t("deleted_author")
        @document.paragraph("##{comment.id} · #{author} · #{comment.created_at.iso8601}", indent: depth)
        @document.html(translate(comment.body), indent: depth)
        grouped.fetch([comment.class.name, comment.id], []).each { |reply| write_comment(reply, grouped, depth + 1) }
      end

      def translate(value)
        return value.to_s unless value.is_a?(Hash)

        value[@locale].presence || value[@component.organization.default_locale].presence || value.values.find { |item|
          item.is_a?(String) && item.present?
        }.to_s
      end

      def t(key, **options)
        I18n.t(key, scope: "decidim.enhanced_textwork.export", **options)
      end
    end
  end
end
